import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "root:/"
import "root:/singletons"
import "root:/components"

PanelWindow {
    id: logitechOverlay

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // ── data ─────────────────────────────────────────────────────────────────
    property var devices: []

    function batteryColor(level, connected) {
        if (!connected) return Theme.overlay0
        if (level <= 10) return Theme.red
        if (level <= 25) return Theme.peach
        if (level <= 50) return Theme.yellow
        return Theme.green
    }

    function batteryIcon(level, connected) {
        if (!connected) return "battery-warning"
        if (level >= 90) return "battery-full"
        if (level >= 60) return "battery-high"
        if (level >= 35) return "battery-medium"
        if (level >= 15) return "battery-low"
        if (level > 5)   return "battery-empty"
        return "battery-warning"
    }

    function refresh() {
        listProc.running = false
        listProc.running = true
    }

    // Parse `openlogi list` output into device objects
    Process {
        id: listProc
        command: ["openlogi", "list"]
        stdout: SplitParser {
            property var incoming: []
            onRead: line => {
                // Match lines like: ├─ slot 1 ● MX Master3 Mac (mouse, ..., battery=20% low (discharging))
                var m = line.match(/slot\s+(\d+)\s+(●|○)\s+(.+?)\s+\(([^,]+),.*?battery=([^)]+)\)/)
                if (m) {
                    var connected = m[2] === "●"
                    var batteryRaw = m[5].trim()  // e.g. "20% low (discharging)" or "—"
                    var levelMatch = batteryRaw.match(/(\d+)%/)
                    var level = levelMatch ? parseInt(levelMatch[1]) : -1
                    var statusMatch = batteryRaw.match(/\(([^)]+)\)/)
                    var status = statusMatch ? statusMatch[1] : (connected ? "Unknown" : "Offline")
                    incoming = incoming.concat([{
                        slot:      parseInt(m[1]),
                        connected: connected,
                        name:      m[3].trim(),
                        type:      m[4].trim(),
                        level:     level,
                        status:    status,
                        batteryRaw: batteryRaw
                    }])
                }
            }
        }
        onExited: {
            if (listProc.stdout.incoming.length > 0)
                logitechOverlay.devices = listProc.stdout.incoming
            listProc.stdout.incoming = []
        }
        onRunningChanged: { if (running) listProc.stdout.incoming = [] }
    }

    Timer {
        interval: 10000
        running: logitechOverlay.visible
        repeat: true
        onTriggered: logitechOverlay.refresh()
    }

    onVisibleChanged: { if (visible) refresh() }

    // ── UI ───────────────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: AppState.toggleLogitechOverlay()
        z: -1
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 12
            rightMargin: Math.min(AppState.screenWidth - 300 - 10, Math.max(10, AppState.screenWidth - AppState.lastClickX - 300 / 2))
        }
        width: 300
        height: content.implicitHeight + 40
        color: Theme.mantle
        radius: Config.overlayRadius
        border.color: Theme.surface0
        border.width: 1

        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
            id: content
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 20
            }
            spacing: 16

            // ── Header ────────────────────────────────────────────────────
            Item {
                width: parent.width
                height: 24

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    SvgIcon {
                        name: "mouse"
                        size: 16
                        color: Theme.text
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Devices"
                        color: Theme.text
                        font.pixelSize: 16
                        font.bold: true
                        font.family: Config.moduleFontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    radius: 14
                    color: refreshMouse.containsMouse ? Theme.surface1 : Theme.surface0

                    SvgIcon {
                        anchors.centerIn: parent
                        name: "refresh"
                        size: 13
                        color: Theme.subtext0
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: logitechOverlay.refresh()
                    }
                }
            }

            // ── Device list ───────────────────────────────────────────────
            Column {
                width: parent.width
                spacing: 10

                Repeater {
                    model: logitechOverlay.devices

                    Rectangle {
                        width: parent.width
                        height: deviceCol.implicitHeight + 24
                        color: Theme.surface0
                        radius: Config.moduleRadius
                        opacity: modelData.connected ? 1.0 : 0.6

                        Column {
                            id: deviceCol
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 14
                            }
                            spacing: 10

                            // Name + status row
                            Item {
                                width: parent.width
                                height: 32

                                Row {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 10

                                    SvgIcon {
                                        name: modelData.level >= 0
                                            ? logitechOverlay.batteryIcon(modelData.level, modelData.connected)
                                            : "battery-warning"
                                        size: 22
                                        color: logitechOverlay.batteryColor(modelData.level, modelData.connected)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        Text {
                                            text: modelData.name
                                            color: Theme.text
                                            font.pixelSize: 13
                                            font.bold: true
                                            font.family: Config.moduleFontFamily
                                        }

                                        Text {
                                            text: modelData.type + " · " + (modelData.connected ? modelData.status : "Offline")
                                            color: Theme.overlay1
                                            font.pixelSize: 10
                                            font.family: Config.moduleFontFamily
                                        }
                                    }
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.level >= 0 ? modelData.level + "%" : "—"
                                    color: logitechOverlay.batteryColor(modelData.level, modelData.connected)
                                    font.pixelSize: 22
                                    font.bold: true
                                    font.family: Config.moduleFontFamily
                                }
                            }

                            // Progress bar
                            Item {
                                width: parent.width
                                height: 6
                                visible: modelData.level >= 0

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: Theme.surface1
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: parent.height
                                    radius: parent.height / 2
                                    width: Math.max(height, parent.width * (modelData.level / 100))
                                    color: logitechOverlay.batteryColor(modelData.level, modelData.connected)

                                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 300 } }
                                }
                            }
                        }
                    }
                }

                // Empty state
                Text {
                    width: parent.width
                    visible: logitechOverlay.devices.length === 0
                    text: "No devices found"
                    color: Theme.overlay0
                    font.pixelSize: 12
                    font.family: Config.moduleFontFamily
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
