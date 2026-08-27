pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property bool enabled: false
    property string connectedSsid: ""
    property int connectedSignal: 0
    property var networks: []
    property bool scanning: false
    property var pendingCommand: []

    function refresh() {
        statusProcess.running = false
        statusProcess.running = true
        networksProcess.running = false
        networksProcess.running = true
    }

    function toggleWifi() {
        pendingCommand = ["nmcli", "radio", "wifi", enabled ? "off" : "on"]
        commandProcess.running = true
    }

    function connectNetwork(ssid) {
        pendingCommand = ["nmcli", "device", "wifi", "connect", ssid]
        commandProcess.running = true
    }

    function disconnectNetwork() {
        pendingCommand = ["sh", "-c", "nmcli device disconnect $(nmcli -t -f type,device device | grep '^wifi' | cut -d: -f2 | head -1)"]
        commandProcess.running = true
    }

    Process {
        id: commandProcess
        running: false
        command: pendingCommand

        onRunningChanged: {
            if (!running && pendingCommand.length > 0) {
                refreshTimer.start()
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 1500
        running: false
        repeat: false
        onTriggered: refresh()
    }

    // Get wifi enabled state + connected network
    Process {
        id: statusProcess
        running: true
        command: ["sh", "-c", `
            RADIO=$(nmcli radio wifi)
            echo "RADIO:$RADIO"
            nmcli -t -f active,ssid,signal dev wifi list 2>/dev/null | grep "^yes" | while IFS=: read active ssid signal; do
                echo "CONNECTED:$ssid:$signal"
            done
        `]

        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("RADIO:")) {
                    enabled = data.substring(6).trim() === "enabled"
                } else if (data.startsWith("CONNECTED:")) {
                    var parts = data.substring(10).split(":")
                    connectedSsid = parts[0] || ""
                    connectedSignal = parseInt(parts[1]) || 0
                }
            }
        }

        onRunningChanged: {
            if (running) {
                // Don't clear — keep stale values visible until new data arrives
            }
        }
    }

    // Scan and list networks
    Process {
        id: networksProcess
        running: true
        command: ["sh", "-c", `
            nmcli -t -f active,ssid,signal,security dev wifi list 2>/dev/null | sort -t: -k3 -rn | awk -F: '!seen[$2]++' | while IFS=: read active ssid signal security; do
                [ -z "$ssid" ] && continue
                echo "$active|||$ssid|||$signal|||$security"
            done
        `]

        stdout: SplitParser {
            property var incoming: []
            onRead: data => {
                var parts = data.split("|||")
                if (parts.length >= 3) {
                    incoming = incoming.concat([{
                        active:   parts[0] === "yes",
                        ssid:     parts[1],
                        signal:   parseInt(parts[2]) || 0,
                        security: parts[3] || ""
                    }])
                }
            }
        }

        onExited: {
            // Swap in the full new list only when the process finishes,
            // so the overlay never flashes empty mid-refresh
            if (networksProcess.stdout.incoming.length > 0) {
                networks = networksProcess.stdout.incoming
            }
            networksProcess.stdout.incoming = []
        }

        onRunningChanged: {
            if (running) networksProcess.stdout.incoming = []
        }
    }

    // Refresh every 30 seconds
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: refresh()
    }

    Component.onCompleted: refresh()
}
