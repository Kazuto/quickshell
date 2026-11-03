#!/bin/sh
# Lists what could be updated, for singletons/UpdateData.qml. One tab-separated line each:
#   update <source> <name> <version> <note> <id>
#   restart <reason>
#   warning <text>
# Nothing here needs root or changes anything. A manager that's missing or fails is skipped.

export LC_ALL=C
. /etc/os-release

has() {
    command -v "$1" >/dev/null 2>&1
}

# "name old -> new", as checkupdates and the AUR helpers print it
print_arrows() {
    awk -v source="$1" 'NF >= 4 { print "update\t" source "\t" $1 "\t" $4 "\t\t" }'
}

if has apt-get; then
    # A simulation, so this is what an upgrade would really install, without anything held back
    apt-get -s --with-new-pkgs upgrade 2>/dev/null | awk -v release="${VERSION_CODENAME:-}" '
        /^Inst / {
            details = $0
            sub(/^[^(]*\(/, "", details)
            sub(/\).*$/, "", details)
            split(details, parts, " ")

            note = (details ~ /-security/) ? "security" : ""
            if (match(details, /Ubuntu:[^\/]*\/[a-z]+/)) {
                suite = substr(details, RSTART, RLENGTH)
                sub(/.*\//, "", suite)
                if (suite != release) note = "from " suite
            }
            print "update\tapt\t" $2 "\t" parts[1] "\t" note "\t"
        }'

    if [ "${ID:-}" = ubuntu ] && ! apt-cache policy 2>/dev/null | grep -q "o=Ubuntu,.*n=$VERSION_CODENAME"; then
        printf 'warning\tUbuntu %s repositories are missing from your apt sources, so this release gets no updates from them\n' "$VERSION_CODENAME"
    fi
fi

if has pacman; then
    if has checkupdates; then checkupdates 2>/dev/null; else pacman -Qu 2>/dev/null; fi | print_arrows pacman
    if has yay; then yay -Qua 2>/dev/null; elif has paru; then paru -Qua 2>/dev/null; fi | print_arrows aur

    # Upgrading the kernel removes the modules of the one still running
    [ -d "/usr/lib/modules/$(uname -r)" ] || printf 'restart\ta new kernel\n'
fi

if has snap; then
    snap refresh --list 2>/dev/null | awk 'NR > 1 && NF >= 4 { print "update\tsnap\t" $1 "\t" $2 "\t\t" }'
fi

if has flatpak; then
    flatpak remote-ls --updates --columns=application,version 2>/dev/null \
        | awk -F'\t' '$1 != "" { print "update\tflatpak\t" $1 "\t" $2 "\t\t" }'
fi

if has fwupdmgr && has jq; then
    # Older releases are listed too, newest first
    fwupdmgr get-updates --json --no-unreported-check --no-metadata-check 2>/dev/null </dev/null | jq -r '
        .Devices[]? | select(.Releases[0]?)
        | ["update", "firmware", .Name, .Releases[0].Version,
           (if ((.Flags // []) | index("needs-reboot")) then "needs a restart" else "" end), .DeviceId]
        | @tsv' 2>/dev/null
fi

if [ -e /run/reboot-required ]; then
    printf 'restart\t%s\n' "$(paste -sd, /run/reboot-required.pkgs 2>/dev/null)"
fi
