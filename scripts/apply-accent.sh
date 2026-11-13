#!/bin/sh
# Takes the accent color from a wallpaper and hands it to the rest of the desktop.
# Only the accent changes: backgrounds and syntax colors stay Catppuccin Mocha, so
# no wallpaper can make text unreadable.
#
#   apply-accent.sh <image>    derive from the image, unless the accent is fixed
#   apply-accent.sh --derive   start following the wallpaper again
#   apply-accent.sh --fixed    stop following it and use the default accent
#   apply-accent.sh --sync     re-apply the stored accent, for after a Hyprland reload
#
# Generated files stay out of the dotfiles repos. Quickshell and Neovim watch the accent
# file, which is why it's written last and in place.

CACHE="$HOME/.cache/quickshell"
ACCENT_FILE="$CACHE/accent"
FIXED_FLAG="$CACHE/accent-fixed"
SOURCE_FILE="$CACHE/accent-source"
DEFAULT_ACCENT="#f2a7bd"
MOCHA_BASE="1e1e2e"
DARK_TEXT="#11111b"
GTK_BASE="catppuccin-mocha-pink-standard+default"

mkdir -p "$CACHE"

# Saturation counts for more than coverage, since dark wallpapers are mostly slate
# with a faint tint and the vivid part is small. The result is lifted to a lightness
# that reads on Mocha and under dark on-accent text.
pick_accent() {
    magick "$1[0]" -resize 64x64 -colors 16 -format %c histogram:info:- 2>/dev/null | awk '
    function hexval(str, i, v) {
        str = tolower(str); v = 0
        for (i = 1; i <= length(str); i++) v = v * 16 + index("0123456789abcdef", substr(str, i, 1)) - 1
        return v
    }
    function hue2rgb(p, q, t) {
        if (t < 0) t += 1
        if (t > 1) t -= 1
        if (t < 1/6) return p + (q - p) * 6 * t
        if (t < 1/2) return q
        if (t < 2/3) return p + (q - p) * (2/3 - t) * 6
        return p
    }
    {
        if (!match($0, /#[0-9A-Fa-f]{6}/)) next
        hex = substr($0, RSTART + 1, 6)
        count = $1 + 0
        r = hexval(substr(hex, 1, 2)) / 255; g = hexval(substr(hex, 3, 2)) / 255; b = hexval(substr(hex, 5, 2)) / 255
        hi = r; if (g > hi) hi = g; if (b > hi) hi = b
        lo = r; if (g < lo) lo = g; if (b < lo) lo = b
        l = (hi + lo) / 2; d = hi - lo
        c = 2 * l - 1; if (c < 0) c = -c
        s = (d == 0 || c == 1) ? 0 : d / (1 - c)
        if (d == 0) h = 0
        else if (hi == r) h = (g - b) / d + (g < b ? 6 : 0)
        else if (hi == g) h = (b - r) / d + 2
        else h = (r - g) / d + 4
        h /= 6
        score = s * s * s * sqrt(count)
        if (l < 0.2 || l > 0.92) score *= 0.1
        if (score > best) { best = score; bh = h; bs = s }
    }
    END {
        if (best == 0 || bs < 0.15) exit
        s = bs < 0.55 ? 0.55 : (bs > 0.85 ? 0.85 : bs); l = 0.78
        q = l + s - l * s; p = 2 * l - q
        printf "#%02x%02x%02x\n", hue2rgb(p, q, bh + 1/3) * 255 + 0.5, hue2rgb(p, q, bh) * 255 + 0.5, hue2rgb(p, q, bh - 1/3) * 255 + 0.5
    }'
}

# awww only knows the crops of a split wallpaper, so the full image is kept separately
current_wallpaper() {
    image=$(cat "$SOURCE_FILE" 2>/dev/null)
    [ -f "$image" ] || image=$(awww query 2>/dev/null | sed -n 's/.*image: //p' | head -n 1)
    printf '%s' "$image"
}

stored_accent() {
    accent=$(cat "$ACCENT_FILE" 2>/dev/null)
    case "$accent" in
        \#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]) printf '%s' "$accent" ;;
        *) printf '%s' "$DEFAULT_ACCENT" ;;
    esac
}

write_configs() {
    # Yazi's theme.toml draws its accent in palette color 89, so reloading Ghostty
    # recolors open Yazi windows too
    printf 'cursor-color = %s\npalette = 89=%s\n' "$1" "$1" > "$CACHE/accent-ghostty"
    printf 'set -g pane-active-border-style fg=%s\n' "$1" > "$CACHE/accent-tmux.conf"

    # .init points new shells here when this file exists
    if [ -f "$HOME/.config/starship.toml" ]; then
        sed -E "/^\[directory\]/,/^\[[a-z_]+\]$/s/^style = .*/style = \"bold $1\"/" \
            "$HOME/.config/starship.toml" > "$CACHE/accent-starship.toml"
    fi

    write_gtk4_css "$1"
    write_vivaldi_css "$1"
}

find_gtk_base() {
    for dir in "$HOME/.local/share/themes" "$HOME/.themes" /usr/share/themes; do
        if [ -d "$dir/$GTK_BASE/gtk-3.0" ]; then
            printf '%s' "$dir/$GTK_BASE"
            return
        fi
    done
}

# GTK only rereads a theme when its name changes, so the accent alternates between two
# copies of it. Thunar and Chrome's "Use GTK" mode recolor from this without a restart.
apply_gtk() {
    base=$(find_gtk_base)
    [ -n "$base" ] || return 0

    hex=${1#\#}
    green=${hex#??}
    red=$(printf '%d' "0x${hex%????}")
    blue=$(printf '%d' "0x${hex#????}")
    green=$(printf '%d' "0x${green%??}")

    current=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
    [ "$current" = "accent-a" ] && slot="accent-b" || slot="accent-a"
    dir="$HOME/.local/share/themes/$slot"

    rm -rf "$dir"
    mkdir -p "$dir"
    cp -r "$base/gtk-3.0" "$base/gtk-4.0" "$dir/"
    find "$dir" -type f \( -name '*.css' -o -name '*.svg' \) -exec sed -i -E \
        "s/#f5c2e7/$1/gI; s/rgba\(245, ?194, ?231/rgba($red, $green, $blue/g" {} +
    for css in "$dir"/gtk-*/gtk.css "$dir"/gtk-*/gtk-dark.css; do
        gtk_overrides "$1" >> "$css"
    done
    printf '[X-GNOME-Metatheme]\nName=%s\nGtkTheme=%s\n' "$slot" "$slot" > "$dir/index.theme"

    gsettings set org.gnome.desktop.interface gtk-theme "$slot"
}

# Last in the file so these win. The accent is light, so text on it has to be dark.
gtk_overrides() {
    cat <<EOF

.thunar .standard-view.frame widget.view:selected,
.background.csd .view:selected,
.csd treeview.view:selected,
treeview.view:selected,
.view:selected,
.view selection,
entry selection,
textview text selection,
row:selected,
row:selected label,
row:selected image,
button.suggested-action,
button.suggested-action label {
  color: $DARK_TEXT;
}

.sidebar treeview.view:selected,
.sidebar .view:selected,
.background.csd .sidebar .view:selected,
.csd .sidebar treeview.view:selected {
  background-color: $1;
  color: $DARK_TEXT;
}
EOF
}

# libadwaita apps ignore GTK themes and only read this at launch
write_gtk4_css() {
    css="$HOME/.config/gtk-4.0/gtk.css"
    if [ -e "$css" ] && ! grep -q 'apply-accent.sh' "$css"; then
        return 0
    fi
    mkdir -p "${css%/*}"
    cat > "$css" <<EOF
/* Generated by apply-accent.sh */
:root {
  --accent-bg-color: $1;
  --accent-color: $1;
  --accent-fg-color: $DARK_TEXT;
  --window-bg-color: #1e1e2e;
  --window-fg-color: #cdd6f4;
  --view-bg-color: #1e1e2e;
  --view-fg-color: #cdd6f4;
  --headerbar-bg-color: #181825;
  --headerbar-fg-color: #cdd6f4;
  --headerbar-backdrop-color: #181825;
  --sidebar-bg-color: #181825;
  --sidebar-fg-color: #cdd6f4;
  --sidebar-backdrop-color: #181825;
  --secondary-sidebar-bg-color: #1e1e2e;
  --card-bg-color: #313244;
  --popover-bg-color: #313244;
  --popover-fg-color: #cdd6f4;
  --dialog-bg-color: #1e1e2e;
  --dialog-fg-color: #cdd6f4;
}

/* libadwaita tints selections gray, which hides the accent */
.navigation-sidebar > row:selected,
listview > row:selected {
  background-color: color-mix(in srgb, var(--accent-bg-color) 35%, transparent);
}

.nautilus-grid-view gridview > child:selected,
.nautilus-list-view columnview > listview > row:selected {
  background-image: none;
  background-color: color-mix(in srgb, var(--accent-bg-color) 35%, transparent);
  box-shadow: inset 0 0 0 1px var(--accent-bg-color);
}
EOF
}

# Vivaldi has its own themes, so it takes this folder as a CSS mod and reads it at launch
write_vivaldi_css() {
    mkdir -p "$CACHE/vivaldi"
    cat > "$CACHE/vivaldi/accent.css" <<EOF
/* Generated by apply-accent.sh */
#browser {
  --colorHighlightBg: $1 !important;
  --colorHighlightBgDark: $1 !important;
  --colorHighlightFg: $DARK_TEXT !important;
  --colorAccentBg: #1e1e2e !important;
  --colorAccentFg: #cdd6f4 !important;
  --colorBg: #1e1e2e !important;
  --colorBgDark: #181825 !important;
  --colorBgDarker: #11111b !important;
  --colorBgLight: #313244 !important;
  --colorFg: #cdd6f4 !important;
}
EOF
}

# herdr can't include another file, so the accent goes straight into its config, which
# neither dotfiles repo tracks. Writing through the file keeps it a symlink, and an
# unchanged accent leaves the file and the running server alone.
apply_herdr() {
    config="${HERDR_CONFIG_PATH:-$HOME/.config/herdr/config.toml}"
    [ -f "$config" ] || return 0

    # Quickshell's PATH doesn't include ~/.local/bin, where herdr installs itself
    herdr=$(command -v herdr || printf '%s' "$HOME/.local/bin/herdr")

    updated=$(awk -v line="accent = \"$1\"" '
        NR == FNR { if ($0 == "[theme.custom]") has = 1; next }
        /^\[/ {
            if (section == "[theme.custom]" && !done) { print line; done = 1 }
            if (section == "[theme]" && !has && !done) { print "[theme.custom]"; print line; print ""; done = 1 }
            section = $0
        }
        section == "[theme.custom]" && !done && /^#? *accent *=/ { print line; done = 1; next }
        { print }
        END {
            if (!done) {
                if (section != "[theme.custom]") print "\n[theme.custom]"
                print line
            }
        }' "$config" "$config") || return 0

    [ "$updated" = "$(cat "$config")" ] && return 0
    printf '%s\n' "$updated" > "$config"
    [ -x "$herdr" ] && "$herdr" server reload-config >/dev/null 2>&1
}

apply_hyprland() {
    hex=${1#\#}
    # Only a Lua config answers ok to eval. A hyprland.conf needs keyword instead.
    [ "$(hyprctl eval "hl.config({ general = { col = { active_border = { colors = { 'rgb($hex)', 'rgb($MOCHA_BASE)', 'rgb($MOCHA_BASE)', 'rgb($hex)' }, angle = 45 } } } })" 2>/dev/null)" = ok ] ||
        hyprctl keyword general:col.active_border \
            "rgb($hex) rgb($MOCHA_BASE) rgb($MOCHA_BASE) rgb($hex) 45deg" >/dev/null 2>&1
}

apply() {
    write_configs "$1"
    apply_hyprland "$1"
    apply_gtk "$1"
    apply_herdr "$1"
    tmux source-file -q "$CACHE/accent-tmux.conf" >/dev/null 2>&1
    pkill -USR2 -x ghostty 2>/dev/null
    printf '%s\n' "$1" > "$ACCENT_FILE"
}

derive_from() {
    accent=$(pick_accent "$1")
    apply "${accent:-$DEFAULT_ACCENT}"
}

case "${1:-}" in
    --sync)
        accent=$(stored_accent)
        write_configs "$accent"
        apply_hyprland "$accent"
        apply_herdr "$accent"
        case "$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null)" in
            "'accent-a'" | "'accent-b'") ;;
            *) apply_gtk "$accent" ;;
        esac
        [ -f "$ACCENT_FILE" ] || printf '%s\n' "$accent" > "$ACCENT_FILE"
        ;;
    --fixed)
        : > "$FIXED_FLAG"
        apply "$DEFAULT_ACCENT"
        ;;
    --derive)
        rm -f "$FIXED_FLAG"
        derive_from "$(current_wallpaper)"
        ;;
    "")
        echo "usage: apply-accent.sh <image> | --derive | --fixed | --sync" >&2
        exit 1
        ;;
    *)
        printf '%s' "$1" > "$SOURCE_FILE"
        [ -e "$FIXED_FLAG" ] || derive_from "$1"
        ;;
esac
