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

    // Hex color, or "" to use the default accent. Empty also means the
    // "Derive accent from wallpaper" option is off.
    property string accentOverride: ""
    property bool deriveAccent: false
    readonly property string accentPath: "$HOME/.cache/quickshell/accent"
    property string selectedDimensions: ""

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

    // output is an output name, or empty for every output
    function apply(path, output) {
        if (!path || applying) return
        applying = true
        current = path
        var setter = output
            ? "awww img " + root.shellQuote(path) + " --outputs " + root.shellQuote(output) +
              " --resize crop --transition-type grow --transition-duration 0.5 --transition-fps 60 --transition-pos top-right"
            : root.setScript + " " + root.shellQuote(path)
        applyProc.command = ["sh", "-c", setter +
            " && printf '%s' " + root.shellQuote(path) + " > " + root.currentPath]
        applyProc.running = true
        if (deriveAccent) deriveFrom(path)
    }

    function setDeriveAccent(enabled) {
        deriveAccent = enabled
        if (enabled) {
            if (current) deriveFrom(current)
        } else {
            saveAccent("")
        }
    }

    function deriveFrom(path) {
        accentProc.command = ["sh", "-c", "magick " + root.shellQuote(path) +
            " -resize 64x64 -colors 8 -format %c histogram:info:-"]
        accentProc.running = true
    }

    function saveAccent(hex) {
        accentOverride = hex
        Quickshell.execDetached(["sh", "-c", "mkdir -p $HOME/.cache/quickshell && printf '%s' '" +
            hex + "' > " + root.accentPath])
    }

    // Picks the most colorful histogram entry, weighted by how much of the
    // image it covers, then lifts it to a lightness that stays readable on
    // the island and under dark on-accent text.
    function pickAccent(histogram) {
        var best = null
        var bestScore = 0
        var lines = histogram.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var match = lines[i].match(/^\s*(\d+):.*#([0-9A-Fa-f]{6})/)
            if (!match) continue
            var c = Qt.color("#" + match[2])
            var score = c.hslSaturation * Math.sqrt(parseInt(match[1], 10))
            if (c.hslLightness < 0.15 || c.hslLightness > 0.92) score *= 0.2
            if (score > bestScore) {
                bestScore = score
                best = c
            }
        }
        if (!best || best.hslSaturation < 0.12) return ""
        return Qt.hsla(best.hslHue, Math.max(0.45, Math.min(0.85, best.hslSaturation)), 0.78, 1).toString()
    }

    Process {
        id: accentProc
        stdout: StdioCollector {
            onStreamFinished: root.saveAccent(root.pickAccent(this.text))
        }
    }

    function identify(path) {
        selectedDimensions = ""
        if (!path) return
        identifyProc.running = false
        identifyProc.command = ["magick", "identify", "-format", "%w × %h", path + "[0]"]
        identifyProc.running = true
    }

    Process {
        id: identifyProc
        stdout: StdioCollector {
            onStreamFinished: root.selectedDimensions = this.text.trim()
        }
    }

    Process {
        id: loadAccentProc
        command: ["sh", "-c", "cat " + root.accentPath + " 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.accentOverride = this.text.trim()
                root.deriveAccent = root.accentOverride !== ""
            }
        }
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
        loadAccentProc.running = true
        refresh()
    }
}
