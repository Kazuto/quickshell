pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// AI tracking on the EMEET PIXY webcam, through scripts/pixy-track, which talks
// to the camera's vendor HID interface. The camera only says whether it's
// tracking while an app is using it. While it's idle, `mode` is the last known
// one and `confirmed` is false.
Singleton {
    id: root

    readonly property string script: Quickshell.shellDir + "/scripts/pixy-track"

    property bool available: false  // plugged in
    property string mode: ""        // "tracking", "standard", "privacy", or "" if unknown
    property bool confirmed: false
    property string error: ""       // "permission", "no-answer", "not-switched", "failed"
    readonly property bool tracking: mode === "tracking"
    readonly property bool busy: commandProcess.running

    function refresh() {
        if (statusProcess.running || commandProcess.running) return
        statusProcess.running = true
    }

    function toggle() {
        if (busy || !available) return
        commandProcess.command = [script, "--json", "toggle"]
        commandProcess.running = true
    }

    // {"mode", "confirmed", "idle"[, "error"]} or {"error", "message"}
    function apply(output) {
        var result
        try {
            result = JSON.parse(output)
        } catch (e) {
            error = "failed"
            return
        }
        if (result.error === "not-found") {
            available = false
            mode = ""
            error = ""
            return
        }
        available = true
        error = result.error || ""
        if ("mode" in result) {
            mode = result.mode || ""
            confirmed = result.confirmed === true
        }
    }

    Process {
        id: statusProcess
        command: [root.script, "--json", "status"]
        stdout: StdioCollector {
            onStreamFinished: root.apply(text)
        }
    }

    Process {
        id: commandProcess
        stdout: StdioCollector {
            onStreamFinished: root.apply(text)
        }
    }

    Component.onCompleted: refresh()
}
