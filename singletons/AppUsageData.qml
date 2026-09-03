pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var usageCounts: ({})   // { appId: count }
    property bool usageLoaded: false
    readonly property string usagePath: "~/.cache/quickshell/app_usage.json"

    function usageOf(appId) {
        return usageCounts[appId] || 0
    }

    function recordUsage(appId) {
        if (!appId) return
        var next = Object.assign({}, usageCounts)
        next[appId] = (next[appId] || 0) + 1
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

    Component.onCompleted: loadUsageProc.running = true
}
