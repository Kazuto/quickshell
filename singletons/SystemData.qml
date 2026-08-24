pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property string distro: ""
    property string distroVersion: ""
    property string kernel: ""
    property string uptime: ""
    property string de: "Hyprland"

    function refresh() {
        // Get distro
        distroProcess.running = false
        distroProcess.running = true

        // Get kernel
        kernelProcess.running = false
        kernelProcess.running = true

        // Get uptime
        uptimeProcess.running = false
        uptimeProcess.running = true
    }

    Process {
        id: distroProcess
        running: true
        command: ["sh", "-c", "grep -E '^(NAME|VERSION)=' /etc/os-release | cut -d'\"' -f2 | sed -E 's/\\s*\\([^)]*\\)//'"]

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim()
                if (!line) return
                if (!distro) {
                    distro = line
                } else {
                    distroVersion = line
                }
            }
        }
    }

    Process {
        id: kernelProcess
        running: true
        command: ["uname", "-r"]

        stdout: SplitParser {
            onRead: data => {
                kernel = data.trim()
            }
        }
    }

    Process {
        id: uptimeProcess
        running: true
        command: ["sh", "-c", "uptime -p | sed 's/up //'"]

        stdout: SplitParser {
            onRead: data => {
                uptime = data.trim()
            }
        }
    }

    Timer {
        interval: 60000  // Update every minute
        running: true
        repeat: true
        onTriggered: refresh()
    }

    Component.onCompleted: {
        refresh()
    }
}
