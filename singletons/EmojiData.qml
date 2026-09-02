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

    function usageOf(glyph) {
        return usageCounts[glyph] || 0
    }

    function recordUsage(glyph) {
        var next = Object.assign({}, usageCounts)
        next[glyph] = (next[glyph] || 0) + 1
        usageCounts = next
        saveUsage()
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
        "/usr/lib/python3/dist-packages/picker/data/emojis_smileys_emotion.csv",
        "/usr/lib/python3/dist-packages/picker/data/emojis_people_body.csv",
        "/usr/lib/python3/dist-packages/picker/data/emojis_animals_nature.csv",
        "/usr/lib/python3/dist-packages/picker/data/emojis_food_drink.csv",
        "/usr/lib/python3/dist-packages/picker/data/emojis_travel_places.csv",
        "/usr/lib/python3/dist-packages/picker/data/emojis_activities.csv",
        "/usr/lib/python3/dist-packages/picker/data/emojis_objects.csv",
        "/usr/lib/python3/dist-packages/picker/data/emojis_symbols.csv",
        "/usr/lib/python3/dist-packages/picker/data/emojis_flags.csv"
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
        return { glyph: glyph, name: name, keywords: keywords }
    }

    Process {
        id: loadProc
        command: ["cat"].concat(root.dataFiles)
        stdout: SplitParser {
            property var incoming: []
            onRead: line => {
                var entry = root.parseLine(line)
                if (entry) incoming = incoming.concat([entry])
            }
        }
        onExited: {
            root.emojis = loadProc.stdout.incoming
            root.loaded = true
        }
    }

    Component.onCompleted: {
        loadProc.running = true
        loadUsageProc.running = true
    }
}
