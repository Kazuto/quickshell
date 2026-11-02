pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property int level: 0  // 0–100

    function refresh() {
        readProcess.running = false
        readProcess.running = true
    }

    function set(value) {
        level = Math.round(value)
        Quickshell.execDetached(["brightnessctl", "-c", "backlight", "set", level + "%"])
    }

    // The laptop's own panel only; external monitors keep their own controls.
    // Machine-readable output: device,class,current,percent%,max
    Process {
        id: readProcess
        running: true
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                var fields = this.text.trim().split(",")
                root.available = fields.length >= 4
                if (root.available) root.level = parseInt(fields[3], 10) || 0
            }
        }
    }
}
