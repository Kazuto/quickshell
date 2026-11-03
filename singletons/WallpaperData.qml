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

    // scripts/apply-accent.sh owns the accent: it runs whenever a wallpaper is set
    // and also updates the other apps, so this only follows what it writes.
    readonly property string accentScript: Quickshell.shellDir + "/scripts/apply-accent.sh"
    property string accentOverride: ""
    property bool deriveAccent: true
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
        // set-wallpaper.sh updates the accent itself, for its other callers
        var setter = output
            ? "awww img " + root.shellQuote(path) + " --outputs " + root.shellQuote(output) +
              " --resize crop --transition-type grow --transition-duration 0.5 --transition-fps 60 --transition-pos top-right" +
              " && " + root.shellQuote(root.accentScript) + " " + root.shellQuote(path)
            : root.setScript + " " + root.shellQuote(path)
        applyProc.command = ["sh", "-c", setter +
            " && printf '%s' " + root.shellQuote(path) + " > " + root.currentPath]
        applyProc.running = true
    }

    Process {
        id: applyProc
        onExited: root.applying = false
    }

    function setDeriveAccent(enabled) {
        deriveAccent = enabled
        Quickshell.execDetached([root.accentScript, enabled ? "--derive" : "--fixed"])
    }

    FileView {
        id: accentFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/accent"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            // Rewritten in place, so a read can land between truncate and write
            var hex = text().trim()
            if (/^#[0-9a-fA-F]{6}$/.test(hex)) root.accentOverride = hex
        }
    }

    Process {
        id: loadDeriveProc
        command: ["sh", "-c", "test -e $HOME/.cache/quickshell/accent-fixed"]
        onExited: (exitCode, exitStatus) => { root.deriveAccent = exitCode !== 0 }
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
        loadDeriveProc.running = true
        refresh()
    }
}
