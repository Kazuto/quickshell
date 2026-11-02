pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var emojis: []      // [{ glyph, name, keywords }]
    property bool loaded: false

    // ── Usage tracking (persisted to disk) ──────────────────────────────
    property var usageCounts: ({})   // { glyph: count }
    property bool usageLoaded: false
    readonly property string usagePath: "~/.cache/quickshell/emoji_usage.json"

    readonly property var kaomoji: [
        { glyph: "¯\\_(ツ)_/¯", name: "shrug", keywords: "whatever", category: "kaomoji" },
        { glyph: "(╯°□°)╯︵ ┻━┻", name: "table flip", keywords: "angry rage", category: "kaomoji" },
        { glyph: "┬─┬ノ( º _ ºノ)", name: "put table back", keywords: "calm", category: "kaomoji" },
        { glyph: "( ͡° ͜ʖ ͡°)", name: "lenny", keywords: "smirk", category: "kaomoji" },
        { glyph: "(ಠ_ಠ)", name: "disapproval", keywords: "stare", category: "kaomoji" },
        { glyph: "(づ｡◕‿‿◕｡)づ", name: "hug", keywords: "love", category: "kaomoji" },
        { glyph: "(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧", name: "sparkles", keywords: "magic happy", category: "kaomoji" },
        { glyph: "(•_•)", name: "neutral", keywords: "blank", category: "kaomoji" },
        { glyph: "(^_^;)", name: "nervous", keywords: "sweat", category: "kaomoji" },
        { glyph: "(T_T)", name: "crying", keywords: "sad", category: "kaomoji" },
        { glyph: "ʕ•ᴥ•ʔ", name: "bear", keywords: "cute", category: "kaomoji" },
        { glyph: "(=^･ω･^=)", name: "cat", keywords: "cute", category: "kaomoji" }
    ]

    function usageOf(glyph) {
        return usageCounts[glyph] || 0
    }

    function recordUsage(glyph) {
        var next = Object.assign({}, usageCounts)
        next[glyph] = (next[glyph] || 0) + 1
        usageCounts = next
        saveUsage()
    }

    // Copies the glyph and, unless copyOnly, pastes it into whichever window
    // gets focus back once the picker has closed.
    function commit(glyph, copyOnly) {
        recordUsage(glyph)
        Quickshell.execDetached(["wl-copy", glyph])
        if (!copyOnly) typeTimer.restart()
    }

    Timer {
        id: typeTimer
        interval: 320
        repeat: false
        // Ctrl+V rather than typing raw Unicode: Chromium/Electron apps don't
        // reliably accept synthetic emoji keysyms from wtype.
        onTriggered: Quickshell.execDetached(["wtype", "-M", "ctrl", "-k", "v", "-m", "ctrl"])
    }

    function shellQuote(str) {
        return "'" + str.replace(/'/g, "'\\''") + "'"
    }

    function saveUsage() {
        var json = JSON.stringify(usageCounts)
        saveProc.command = ["sh", "-c",
            "mkdir -p ~/.cache/quickshell && printf '%s' " + root.shellQuote(json) + " > " + root.usagePath]
        saveProc.running = true
    }

    Process {
        id: saveProc
        running: false
    }

    Process {
        id: loadUsageProc
        command: ["sh", "-c", "cat " + root.usagePath + " 2>/dev/null"]
        stdout: SplitParser {
            property string collected: ""
            onRead: line => { collected += line }
        }
        onExited: {
            try {
                var parsed = JSON.parse(loadUsageProc.stdout.collected)
                if (parsed && typeof parsed === "object") root.usageCounts = parsed
            } catch (e) {
                // no usage file yet, or invalid — start fresh
            }
            root.usageLoaded = true
        }
    }

    readonly property var dataFiles: [
        "smileys_emotion",
        "people_body",
        "animals_nature",
        "food_drink",
        "travel_places",
        "activities",
        "objects",
        "symbols",
        "flags"
    ]

    function parseLine(line) {
        // Format: "<glyph> <name> <small>(kw1, kw2, ...)</small>"
        var spaceIdx = line.indexOf(" ")
        if (spaceIdx < 0) return null
        var glyph = line.substring(0, spaceIdx)
        var rest = line.substring(spaceIdx + 1)

        var smallIdx = rest.indexOf("<small>")
        var name = smallIdx >= 0 ? rest.substring(0, smallIdx).trim() : rest.trim()

        var keywords = ""
        var kwMatch = rest.match(/<small>\(([^)]*)\)<\/small>/)
        if (kwMatch) keywords = kwMatch[1]

        if (!glyph || !name) return null
        return { glyph: glyph, name: name, keywords: keywords, category: "other" }
    }

    Process {
        id: loadProc
        // rofimoji's data: dist-packages on Debian and Ubuntu, a versioned
        // site-packages directory on Arch
        command: ["sh", "-c", `
            for dir in /usr/lib/python3/dist-packages/picker/data /usr/lib/python3*/site-packages/picker/data; do
                [ -d "$dir" ] || continue
                for name in "$@"; do
                    echo "#FILE:$name"
                    cat "$dir/emojis_$name.csv"
                done
                break
            done
        `, "sh"].concat(root.dataFiles)
        stdout: SplitParser {
            property var incoming: []
            property string category: "other"
            onRead: line => {
                if (line.startsWith("#FILE:")) {
                    category = line.indexOf("smileys") >= 0 ? "smileys"
                        : line.indexOf("people") >= 0 ? "people"
                        : line.indexOf("symbols") >= 0 ? "symbols" : "other"
                    return
                }
                var entry = root.parseLine(line)
                if (entry) {
                    entry.category = category
                    incoming = incoming.concat([entry])
                }
            }
        }
        onExited: {
            root.emojis = loadProc.stdout.incoming.concat(root.kaomoji)
            root.loaded = true
        }
    }

    Component.onCompleted: {
        loadProc.running = true
        loadUsageProc.running = true
    }
}
