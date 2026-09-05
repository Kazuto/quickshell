pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Note: use $HOME rather than ~ in these — ~ only expands when unquoted
    // and at the start of a word, which broke once it landed inside a
    // double-quoted "thumb=..." assignment below.
    readonly property string wallpaperDir: "$HOME/Wallpaper"
    readonly property string thumbDir: "$HOME/.cache/quickshell/wallpaper-thumbs"
    readonly property string setScript: "$HOME/.config/swww/set-wallpaper.sh"
    readonly property string currentPath: "$HOME/.cache/quickshell/current_wallpaper"

    property var wallpapers: []   // [{ name, path, thumb }]
    property bool loaded: false
    property string current: ""
    property bool applying: false

    function shellQuote(str) {
        return "'" + str.replace(/'/g, "'\\''") + "'"
    }

    function refresh() {
        wallpapers = []
        loaded = false
        listProc.running = false
        listProc.running = true
    }

    // Lists wallpapers, generating a small cached JPG thumbnail for each
    // (Qt has no AVIF image-format plugin, but ImageMagick can read AVIF and
    // re-encode a thumbnail we can actually display). Emits one line per
    // wallpaper as its thumbnail becomes ready, so the picker can populate
    // progressively instead of waiting for the whole directory to finish.
    // The target resolution is baked into the cache filename so bumping it
    // (e.g. for a larger carousel preview) automatically invalidates old
    // low-res thumbnails instead of silently reusing them.
    readonly property string thumbSize: "960x540"

    Process {
        id: listProc
        command: ["sh", "-c", `
            mkdir -p ` + root.thumbDir + `
            find ` + root.wallpaperDir + ` -maxdepth 1 -type f \\( -iname '*.avif' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \\) | sort | while read -r f; do
                hash=$(printf '%s' "$f-` + root.thumbSize + `" | md5sum | cut -d' ' -f1)
                thumb="` + root.thumbDir + `/$hash.jpg"
                if [ ! -f "$thumb" ]; then
                    magick "$f" -auto-orient -thumbnail ` + root.thumbSize + `^ -gravity center -extent ` + root.thumbSize + ` -quality 90 "$thumb" 2>/dev/null
                fi
                if [ -f "$thumb" ]; then
                    echo "WP:$f|||$thumb"
                fi
            done
        `]
        stdout: SplitParser {
            onRead: line => {
                if (!line.startsWith("WP:")) return
                var parts = line.substring(3).split("|||")
                if (parts.length < 2) return
                root.wallpapers = root.wallpapers.concat([{
                    name: parts[0].split("/").pop(),
                    path: parts[0],
                    thumb: parts[1]
                }])
            }
        }
        onExited: root.loaded = true
    }

    function apply(path) {
        if (!path || applying) return
        applying = true
        current = path
        applyProc.command = ["sh", "-c",
            root.setScript + " " + root.shellQuote(path) +
            " && printf '%s' " + root.shellQuote(path) + " > " + root.currentPath]
        applyProc.running = true
    }

    Process {
        id: applyProc
        onExited: root.applying = false
    }

    Process {
        id: loadCurrentProc
        command: ["sh", "-c", "cat " + root.currentPath + " 2>/dev/null"]
        stdout: SplitParser {
            property string collected: ""
            onRead: line => { collected += line }
        }
        onExited: root.current = loadCurrentProc.stdout.collected.trim()
    }

    Component.onCompleted: {
        loadCurrentProc.running = true
        refresh()
    }
}
