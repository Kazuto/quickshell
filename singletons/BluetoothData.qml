pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool powered: false
    property string connectedDevice: ""
    property var devices: []
    property var pendingCommand: []
    property bool scanning: false

    // bluetoothctl lists unnamed devices by their address, which only clutters a scan
    readonly property var paired: devices.filter(d => d.paired)
    readonly property var nearby: devices.filter(d => !d.paired && !/^([0-9A-F]{2}-){5}[0-9A-F]{2}$/.test(d.name))

    function scan() {
        if (scanning) return
        scanning = true
        scanProcess.running = true
    }

    function pairDevice(address) {
        pendingCommand = ["sh", "-c", "bluetoothctl --timeout 15 pair " + address +
            " && bluetoothctl trust " + address + " && bluetoothctl connect " + address]
        commandProcess.running = true
    }

    function iconFor(device) {
        if (device.icon.indexOf("mouse") >= 0) return "mouse"
        if (device.icon.indexOf("keyboard") >= 0) return "keyboard"
        if (device.icon.indexOf("audio") >= 0) return "volume"
        return "bluetooth"
    }

    Process {
        id: scanProcess
        command: ["bluetoothctl", "--timeout", "12", "scan", "on"]
        onExited: {
            root.scanning = false
            root.updateStatus()
        }
    }

    function updateStatus() {
        statusProcess.running = false
        statusProcess.running = true
        devicesProcess.running = false
        devicesProcess.running = true
    }

    function togglePower() {
        pendingCommand = ["bluetoothctl", "power", powered ? "off" : "on"]
        commandProcess.running = true
    }

    function connectDevice(address) {
        pendingCommand = ["bluetoothctl", "connect", address]
        commandProcess.running = true
    }

    function disconnectDevice(address) {
        pendingCommand = ["bluetoothctl", "disconnect", address]
        commandProcess.running = true
    }

    // Process for executing commands
    Process {
        id: commandProcess
        running: false
        command: pendingCommand

        onRunningChanged: {
            if (!running && pendingCommand.length > 0) {
                updateTimer.start()
            }
        }
    }

    Timer {
        id: updateTimer
        interval: 500
        running: false
        repeat: false
        onTriggered: updateStatus()
    }

    // Get Bluetooth status and connected device
    Process {
        id: statusProcess
        running: true
        command: ["sh", "-c", `
            # Check if powered
            POWERED=$(bluetoothctl show | grep "Powered: yes" | wc -l)
            echo "POWERED:$POWERED"

            # Get connected device
            bluetoothctl devices | while read line; do
                ADDR=$(echo "$line" | awk '{print $2}')
                NAME=$(echo "$line" | cut -d' ' -f3-)
                CONNECTED=$(bluetoothctl info "$ADDR" | grep "Connected: yes" | wc -l)
                if [ "$CONNECTED" = "1" ]; then
                    echo "CONNECTED:$NAME"
                fi
            done
        `]

        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("POWERED:"))   { powered = data.substring(8) === "1"; return }
                if (data.startsWith("CONNECTED:")) { statusProcess.foundDevice = data.substring(10) }
            }
        }

        property string foundDevice: ""

        onExited: {
            connectedDevice = foundDevice
            foundDevice = ""
        }
    }

    // Get list of devices
    Process {
        id: devicesProcess
        running: true
        command: ["sh", "-c", `
            bluetoothctl devices | while read line; do
                ADDR=$(echo "$line" | awk '{print $2}')
                NAME=$(echo "$line" | cut -d' ' -f3-)
                INFO=$(bluetoothctl info "$ADDR")
                CONNECTED=$(echo "$INFO" | grep -c "Connected: yes")
                PAIRED=$(echo "$INFO" | grep -c "Paired: yes")
                ICON=$(echo "$INFO" | awk -F': ' '/Icon:/{print $2}')
                echo "$ADDR|||$NAME|||$CONNECTED|||$PAIRED|||$ICON"
            done
        `]

        // Swapped in whole once finished, so a panel showing the list doesn't
        // collapse and regrow on every poll.
        stdout: SplitParser {
            property var incoming: []
            onRead: data => {
                var parts = data.split("|||")
                if (parts.length === 5) {
                    incoming = incoming.concat([{
                        address: parts[0],
                        name: parts[1],
                        connected: parts[2] === "1",
                        paired: parts[3] === "1",
                        icon: parts[4]
                    }])
                }
            }
        }

        onExited: {
            devices = devicesProcess.stdout.incoming
            devicesProcess.stdout.incoming = []
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            statusProcess.running = false
            statusProcess.running = true
            devicesProcess.running = false
            devicesProcess.running = true
        }
    }

    Component.onCompleted: {
        updateStatus()
    }
}
