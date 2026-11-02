pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var devices: []  // [{ slot, connected, name, kind, level, status }]
    property int lowBatteryThreshold: 20

    // The device the control center summarizes: the first one online
    readonly property var primary: {
        for (var i = 0; i < devices.length; i++) {
            if (devices[i].connected) return devices[i]
        }
        return devices.length > 0 ? devices[0] : null
    }
    readonly property string deviceName: primary ? primary.name : "No devices"
    readonly property int level: primary ? primary.level : -1
    readonly property bool low: level >= 0 && level <= lowBatteryThreshold

    function refresh() {
        if (!listProcess.running) listProcess.running = true
    }

    // Lines look like: ├─ slot 1 ● MX Master3 Mac (mouse, ..., battery=20% low (discharging))
    Process {
        id: listProcess
        command: ["openlogi", "list"]
        stdout: SplitParser {
            property var incoming: []
            onRead: line => {
                var m = line.match(/slot\s+(\d+)\s+(●|○)\s+(.+?)\s+\(([^,]+),.*?battery=([^)]+)\)/)
                if (!m) return
                var connected = m[2] === "●"
                var battery = m[5].trim()
                var levelMatch = battery.match(/(\d+)%/)
                var statusMatch = battery.match(/\(([^)]+)\)?/)
                incoming = incoming.concat([{
                    slot: parseInt(m[1], 10),
                    connected: connected,
                    name: m[3].trim(),
                    // openlogi reports its mice as keyboards too, so go by the name first
                    kind: /master|anywhere|mouse|ergo|lift|trackball/i.test(m[3]) ? "mouse" : m[4].trim(),
                    level: levelMatch ? parseInt(levelMatch[1], 10) : -1,
                    status: connected ? (statusMatch ? statusMatch[1] : "connected") : "offline"
                }])
            }
        }
        onExited: {
            if (listProcess.stdout.incoming.length > 0) root.devices = listProcess.stdout.incoming
            listProcess.stdout.incoming = []
        }
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
