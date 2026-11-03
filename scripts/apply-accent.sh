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
# Generated files stay in the cache so the dotfiles repos stay clean. Quickshell and
# Neovim watch the accent file, which is why it's written last and in place.

CACHE="$HOME/.cache/quickshell"
ACCENT_FILE="$CACHE/accent"
FIXED_FLAG="$CACHE/accent-fixed"
SOURCE_FILE="$CACHE/accent-source"
DEFAULT_ACCENT="#f2a7bd"
MOCHA_BASE="1e1e2e"

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
}

apply_hyprland() {
    hex=${1#\#}
    hyprctl keyword general:col.active_border \
        "rgb($hex) rgb($MOCHA_BASE) rgb($MOCHA_BASE) rgb($hex) 45deg" >/dev/null 2>&1
}

apply() {
    write_configs "$1"
    apply_hyprland "$1"
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
