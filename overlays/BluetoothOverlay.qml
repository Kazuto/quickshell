import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/singletons"
import "root:/components"

PanelWindow {
    id: bluetoothOverlay

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

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: AppState.toggleBluetoothOverlay()
        z: -1
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 12
            rightMargin: Math.min(AppState.screenWidth - 350 - 10, Math.max(10, AppState.screenWidth - AppState.lastClickX - 350 / 2))  // Position overlay near Bluetooth module
        }
        width: 350
        height: contentColumn.implicitHeight + 40
        color: Theme.mantle
        radius: Config.overlayRadius
        border.color: Theme.surface0
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: {} // Prevent clicks from passing through to background
        }

        Column {
            id: contentColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 20
            }
            spacing: 15

            // Header with power toggle
            Item {
                width: parent.width
                height: 30

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    SvgIcon {
                        name: "bluetooth"
                        size: 18
                        color: BluetoothData.powered ? Theme.sky : Theme.overlay0
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Bluetooth"
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
                    width: 52
                    height: 28
                    color: powerMouseArea.containsMouse ? Theme.surface1 : Theme.surface0
                    radius: 14

                    Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        color: BluetoothData.powered ? Theme.sky : Theme.overlay0
                        x: BluetoothData.powered ? parent.width - width - 3 : 3
                        y: 3
                        Behavior on x { NumberAnimation { duration: 200 } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    MouseArea {
                        id: powerMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothData.togglePower()
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.surface0
            }

            // Devices list
            Column {
                width: parent.width
                spacing: 10

                Repeater {
                    model: BluetoothData.devices

                    Rectangle {
                        width: parent.width
                        height: 50
                        color: deviceMouseArea.containsMouse ? Theme.surface1 : Theme.surface0
                        radius: Config.moduleRadius

                        Row {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 15
                            }
                            spacing: 15

                            SvgIcon {
                                name: "bluetooth"
                                size: 20
                                color: modelData.connected ? Theme.green : Theme.overlay0
                            }

                            Column {
                                width: parent.width - 100
                                spacing: 2

                                Text {
                                    text: modelData.name
                                    color: Theme.text
                                    font.pixelSize: 14
                                    font.family: Config.moduleFontFamily
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: modelData.connected ? "Connected" : "Disconnected"
                                    color: modelData.connected ? Theme.green : Theme.overlay0
                                    font.pixelSize: 11
                                    font.family: Config.moduleFontFamily
                                }
                            }
                        }

                        MouseArea {
                            id: deviceMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.connected) {
                                    BluetoothData.disconnectDevice(modelData.address)
                                } else {
                                    BluetoothData.connectDevice(modelData.address)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
