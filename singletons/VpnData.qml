pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // NetworkManager's VPN profile, preferring one that's up. Empty if there isn't one.
    property string connectionName: ""
    property string state: ""
    readonly property bool available: connectionName !== ""
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

    // Lines look like "yes:activated:vpn:Some name", with any ":" in the name escaped
    function readProfiles(output) {
        var found = null
        var lines = output.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var profile = lines[i].match(/^(yes|no):([^:]*):(vpn|wireguard):(.*)$/)
            if (profile && (!found || (profile[1] === "yes" && found[1] !== "yes")))
                found = profile
        }
        connectionName = found ? found[4].replace(/\\(.)/g, "$1") : ""
        state = found ? found[2] : ""
    }

    function toggle() {
        if (!available || busy || checking) return
        error = ""
        commandPending = true
        // Capture the requested action once; never interrupt an in-flight nmcli command.
        commandProcess.command = ["nmcli", "--wait", "60", "connection", connected ? "down" : "up", connectionName]
        commandProcess.running = true
    }

    Process {
        id: statusProcess
        command: ["env", "LC_ALL=C", "nmcli", "-t", "-f", "ACTIVE,STATE,TYPE,NAME", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.readProfiles(text)
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
