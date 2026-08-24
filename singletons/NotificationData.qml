pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property int count: 0
    property bool paused: false
    property var notifications: []

    function refresh() {
        historyProcess.running = false
        historyProcess.running = true
        countProcess.running = false
        countProcess.running = true
        pausedProcess.running = false
        pausedProcess.running = true
    }

    function closeNotification(id) {
        commandProcess.command = ["dunstctl", "history-rm", id.toString()]
        commandProcess.running = true
    }

    function clearAll() {
        commandProcess.command = ["dunstctl", "history-clear"]
        commandProcess.running = true
    }

    function togglePause() {
        commandProcess.command = ["dunstctl", "set-paused", "toggle"]
        commandProcess.running = true
    }

    Process {
        id: commandProcess
        running: false
        onExited: refreshTimer.start()
    }

    Timer {
        id: refreshTimer
        interval: 300
        running: false
        repeat: false
        onTriggered: refresh()
    }

    // Get notification count
    Process {
        id: countProcess
        running: true
        command: ["dunstctl", "count", "history"]

        stdout: SplitParser {
            onRead: data => {
                count = parseInt(data) || 0
            }
        }
    }

    // Get pause status
    Process {
        id: pausedProcess
        running: true
        command: ["dunstctl", "is-paused"]

        stdout: SplitParser {
            onRead: data => {
                paused = data.trim() === "true"
            }
        }
    }

    // Get notification history
    Process {
        id: historyProcess
        running: true
        command: ["sh", "-c", "dunstctl history | jq -r '.data[] | .[] | \"\\(.id.data)|||\\(.summary.data)|||\\(.body.data)|||\\(.appname.data)|||\\(.timestamp.data)\"'"]

        stdout: SplitParser {
            onRead: data => {
                var parts = data.split("|||")
                if (parts.length === 5) {
                    notifications = notifications.concat([{
                        id: parseInt(parts[0]),
                        summary: parts[1],
                        body: parts[2],
                        appname: parts[3],
                        timestamp: parseInt(parts[4])
                    }])
                }
            }
        }

        onRunningChanged: {
            if (running) {
                notifications = []
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            countProcess.running = false
            countProcess.running = true
            pausedProcess.running = false
            pausedProcess.running = true
        }
    }

    Component.onCompleted: {
        refresh()
    }
}
