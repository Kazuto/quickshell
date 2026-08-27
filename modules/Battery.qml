import QtQuick
import Quickshell.Io
import "root:/"
import "root:/components"
import "root:/singletons"

Rectangle {
    id: root

    implicitWidth: batteryRow.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: Config.moduleBackground
    radius: Config.moduleRadius

    property int capacity: 100
    property string status: "Unknown"  // Charging, Discharging, Not charging, Full

    property bool isCharging: status === "Charging"
    property bool isFull: status === "Full" || (status === "Not charging" && capacity >= 98)

    property color iconColor: {
        if (isCharging || isFull) return Theme.green
        if (capacity <= 10) return Theme.red
        if (capacity <= 25) return Theme.peach
        if (capacity <= 50) return Theme.yellow
        return Theme.subtext0
    }

    property string iconName: {
        if (isCharging) return "battery-charging"
        if (capacity >= 90) return "battery-full"
        if (capacity >= 60) return "battery-high"
        if (capacity >= 35) return "battery-medium"
        if (capacity >= 15) return "battery-low"
        if (capacity > 5)   return "battery-empty"
        return "battery-warning"
    }

    Row {
        id: batteryRow
        anchors.centerIn: parent
        spacing: 6

        SvgIcon {
            name: root.iconName
            size: Config.moduleFontSize
            color: root.iconColor
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.capacity + "%"
            color: root.iconColor
            font.pixelSize: Config.moduleFontSize
            font.family: Config.moduleFontFamily
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Process {
        id: batteryProcess
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity; cat /sys/class/power_supply/BAT0/status"]
        stdout: SplitParser {
            property bool nextIsStatus: false
            onRead: line => {
                var val = parseInt(line)
                if (!isNaN(val)) {
                    root.capacity = val
                    nextIsStatus = true
                } else if (nextIsStatus) {
                    root.status = line.trim()
                    nextIsStatus = false
                }
            }
        }
    }

    function refresh() {
        batteryProcess.running = false
        batteryProcess.running = true
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: { AppState.lastClickX = mapToItem(null, width / 2, 0).x; AppState.toggleBatteryOverlay() }
    }
}
