pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property bool isRunning: false
    property var models: []
    property string loadedModel: ""

    function refresh() {
        // Clear models before refreshing
        models = []
        loadedModel = ""

        // Check if Ollama is running
        statusProcess.running = false
        statusProcess.running = true

        // Get list of models
        modelsProcess.running = false
        modelsProcess.running = true

        // Get loaded model
        psProcess.running = false
        psProcess.running = true
    }

    // Check if Ollama service is running
    Process {
        id: statusProcess
        running: true
        command: ["sh", "-c", "systemctl --user is-active ollama 2>/dev/null || pgrep -x ollama > /dev/null && echo active || echo inactive"]

        stdout: SplitParser {
            onRead: data => {
                var trimmed = data.trim()
                isRunning = trimmed === "active"
            }
        }
    }

    // Get list of models
    Process {
        id: modelsProcess
        running: true
        command: ["sh", "-c", "ollama list 2>/dev/null | tail -n +2 | awk '{print $1 \"|\" $2}'"]

        stdout: SplitParser {
            onRead: data => {
                var trimmed = data.trim()
                if (trimmed.length === 0) return

                var parts = trimmed.split("|")
                if (parts.length === 2) {
                    var modelList = models.slice()
                    modelList.push({
                        name: parts[0],
                        size: parts[1]
                    })
                    models = modelList
                }
            }
        }
    }

    // Get currently loaded model
    Process {
        id: psProcess
        running: true
        command: ["sh", "-c", "ollama ps 2>/dev/null | tail -n +2 | awk '{print $1}' | head -1"]

        stdout: SplitParser {
            onRead: data => {
                var trimmed = data.trim()
                loadedModel = trimmed
            }
        }
    }

    Timer {
        interval: 10000  // Update every 10 seconds
        running: true
        repeat: true
        onTriggered: {
            // Clear models before refreshing
            models = []
            refresh()
        }
    }

    Component.onCompleted: {
        refresh()
    }
}
