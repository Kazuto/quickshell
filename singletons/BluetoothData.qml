pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property bool powered: false
    property string connectedDevice: ""
    property var devices: []
    property var pendingCommand: []

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
                if (data.startsWith("POWERED:")) {
                    powered = data.substring(8) === "1"
                } else if (data.startsWith("CONNECTED:")) {
                    connectedDevice = data.substring(10)
                }
            }
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
                CONNECTED=$(bluetoothctl info "$ADDR" | grep "Connected: yes" | wc -l)
                echo "$ADDR|||$NAME|||$CONNECTED"
            done
        `]

        stdout: SplitParser {
            onRead: data => {
                var parts = data.split("|||")
                if (parts.length === 3) {
                    devices = devices.concat([{
                        address: parts[0],
                        name: parts[1],
                        connected: parts[2] === "1"
                    }])
                }
            }
        }

        onExited: {
            console.log("Found " + devices.length + " Bluetooth devices")
        }

        onRunningChanged: {
            if (running) {
                devices = []
            }
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
