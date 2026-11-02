pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// History comes from cliphist, fed by `wl-paste --watch cliphist store` in
// hyprland.conf. Entries are "<id>\t<preview>".
Singleton {
    id: root

    property var entries: []  // [{ id, preview }]

    function refresh() {
        listProcess.running = false
        listProcess.running = true
    }

    function restore(id) {
        Quickshell.execDetached(["sh", "-c", "printf '%s' '" + id + "' | cliphist decode | wl-copy"])
    }

    Process {
        id: listProcess
        command: ["sh", "-c", "cliphist list | head -n 100"]
        stdout: StdioCollector {
            onStreamFinished: {
                var result = []
                var lines = this.text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var tab = lines[i].indexOf("\t")
                    if (tab <= 0) continue
                    var id = lines[i].substring(0, tab)
                    if (/^\d+$/.test(id)) result.push({ id: id, preview: lines[i].substring(tab + 1) })
                }
                root.entries = result
            }
        }
    }
}
