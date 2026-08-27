import QtQuick
import Quickshell.Io
import "root:/"
import "root:/singletons"
import "root:/components"

Rectangle {
    id: root
    implicitWidth: Config.barHeight
    implicitHeight: Config.barHeight
    color: logitechMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    property string deviceName: "MX Master3 Mac"
    property bool batteryLow: false
    property int lowBatteryThreshold: 20

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    SvgIcon {
        anchors.centerIn: parent
        name: "mouse"
        size: Config.moduleFontSize
        color: root.batteryLow ? Theme.red : Theme.subtext0
    }

    Process {
        id: statusProcess
        command: ["openlogi", "diag", "battery", "--device", root.deviceName]

        property int parsedLevel: -1

        stdout: SplitParser {
            onRead: line => {
                const match = line.match(/discharge_level=(\d+)/)
                if (match) {
                    statusProcess.parsedLevel = parseInt(match[1], 10)
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (parsedLevel >= 0) {
                root.batteryLow = parsedLevel <= root.lowBatteryThreshold
            }
            parsedLevel = -1
        }
    }

    function refreshBatteryStatus() {
        if (statusProcess.running) {
            console.log("openlogi still running, skipping this poll")
            return
        }
        statusProcess.running = true
    }

    Component.onCompleted: refreshBatteryStatus()

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refreshBatteryStatus()
    }

    MouseArea {
        id: logitechMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { AppState.lastClickX = mapToItem(null, width / 2, 0).x; AppState.toggleLogitechOverlay() }
    }
}
