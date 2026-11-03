#!/bin/sh
# Installs updates for singletons/UpdateData.qml. It runs in a terminal, so sudo can ask for a
# password and each manager can show what it's about to do before doing it.
#   run-updates.sh packages
#   run-updates.sh firmware <device id>

# UpdateData checks again when this changes, however the terminal ends up closing
stamp="$HOME/.cache/quickshell/updates-finished"
finish() {
    mkdir -p "${stamp%/*}"
    date > "$stamp"
}
trap finish EXIT
trap 'exit 1' HUP INT TERM

has() {
    command -v "$1" >/dev/null 2>&1
}

heading() {
    printf '\n\033[1m%s\033[0m\n' "$1"
}

case "$1" in
    firmware)
        heading "Firmware"
        fwupdmgr update "$2"
        ;;
    packages)
        if has apt-get; then
            heading "apt"
            sudo apt update && sudo apt upgrade
        fi
        if has pacman; then
            heading "pacman"
            if has yay; then yay -Syu; elif has paru; then paru -Syu; else sudo pacman -Syu; fi
        fi
        if has snap; then
            heading "snap"
            sudo snap refresh
        fi
        if has flatpak; then
            heading "flatpak"
            flatpak update
        fi
        ;;
esac

printf '\nDone. Press Enter to close.'
read -r _
