pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// What could be updated, from scripts/check-updates.sh. Installing happens in a terminal,
// where the package managers can ask for a password and show what they're about to do.
Singleton {
    id: root

    // [{ source, name, version, note, id }], where only firmware has an id
    property var updates: []
    property var warnings: []
    property bool restartNeeded: false
    property string restartReason: ""
    property real checkedAt: 0

    readonly property bool checking: checkProcess.running
    readonly property int packageCount: updates.filter(update => update.source !== "firmware").length
    readonly property bool needsAttention: updates.length > 0 || restartNeeded || warnings.length > 0

    function check() {
        if (!checkProcess.running) checkProcess.running = true
    }

    function readResults(output) {
        var found = []
        var problems = []
        var restart = false
        var reason = ""

        var lines = output.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var fields = lines[i].split("\t")
            if (fields[0] === "update") {
                found.push({ source: fields[1], name: fields[2], version: fields[3], note: fields[4] || "", id: fields[5] || "" })
            } else if (fields[0] === "warning") {
                problems.push(fields[1])
            } else if (fields[0] === "restart") {
                restart = true
                reason = fields[1] || ""
            }
        }

        updates = found
        warnings = problems
        restartNeeded = restart
        restartReason = reason
        checkedAt = Date.now()
    }

    function installPackages() {
        inTerminal(["packages"])
    }

    function installFirmware(deviceId) {
        inTerminal(["firmware", deviceId])
    }

    // Detached, so that reloading the shell can't kill a running upgrade
    function inTerminal(args) {
        Quickshell.execDetached([Quickshell.env("TERMINAL") || "ghostty", "-e",
            Quickshell.shellDir + "/scripts/run-updates.sh"].concat(args))
    }

    Process {
        id: checkProcess
        command: [Quickshell.shellDir + "/scripts/check-updates.sh"]
        stdout: StdioCollector {
            onStreamFinished: root.readResults(this.text)
        }
    }

    // The first check waits for the network and the rest of the login to settle
    Timer {
        interval: root.checkedAt === 0 ? 30000 : 3600000
        running: true
        repeat: true
        onTriggered: root.check()
    }

    // run-updates.sh writes this when it ends
    FileView {
        path: Quickshell.env("HOME") + "/.cache/quickshell/updates-finished"
        watchChanges: true
        printErrors: false
        onFileChanged: {
            reload()
            root.check()
        }
    }
}
