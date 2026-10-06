pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string connectionName: "my-vpn"
    property string state: ""
    readonly property bool connected: state === "activated"
    readonly property bool busy: commandPending || state === "activating" || state === "deactivating"
    readonly property bool checking: statusProcess.running
    property string error: ""
    property bool commandPending: false
    property bool refreshPending: false

    function refresh() {
        if (statusProcess.running) {
            refreshPending = true
            return
        }
        statusProcess.running = true
    }

    function toggle() {
        if (busy || checking) return
        error = ""
        commandPending = true
        // Capture the requested action once; never interrupt an in-flight nmcli command.
        commandProcess.command = ["nmcli", "--wait", "60", "connection", connected ? "down" : "up", connectionName]
        commandProcess.running = true
    }

    Process {
        id: statusProcess
        command: ["env", "LC_ALL=C", "nmcli", "-g", "GENERAL.STATE", "connection", "show", root.connectionName]
        stdout: StdioCollector {
            onStreamFinished: root.state = text.trim()
        }
        onExited: {
            if (root.refreshPending) {
                root.refreshPending = false
                Qt.callLater(root.refresh)
            }
        }
    }

    Process {
        id: commandProcess
        stderr: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            root.commandPending = false
            if (exitCode !== 0)
                root.error = stderr.text.trim() || "VPN command failed (exit " + exitCode + ")"
            root.refresh()
        }
    }

    // Keep both the bar and overlay up to date, including after resume and external changes.
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
