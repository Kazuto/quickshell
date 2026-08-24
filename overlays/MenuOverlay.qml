import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "root:/"
import "root:/singletons"
import "root:/components"

PanelWindow {
    id: menuOverlay

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

    onVisibleChanged: {
        if (visible) {
            SystemData.refresh()
        }
    }

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: AppState.toggleMenuOverlay()
        z: -1
    }

    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            topMargin: 12
            leftMargin: 20
        }
        width: 320
        height: 370
        color: Config.alpha(Theme.base, 0.95)
        radius: Config.overlayRadius
        border.color: Theme.surface0
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Column {
            anchors {
                fill: parent
                margins: 20
            }
            spacing: 20

            // Header
            Text {
                text: Icon.ubuntu + " System"
                color: Theme.text
                font.pixelSize: 18
                font.bold: true
                font.family: Config.moduleFontFamily
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.surface0
            }

            // System Information
            Column {
                width: parent.width
                spacing: 12

                // Distro
                Row {
                    width: parent.width
                    spacing: 10

                    Text {
                        text: "OS"
                        color: Theme.subtext0
                        font.pixelSize: 12
                        font.family: Config.moduleFontFamily
                        width: 80
                    }

                    Text {
                        text: SystemData.distro + " " + SystemData.distroVersion
                        color: Theme.text
                        font.pixelSize: 12
                        font.family: Config.moduleFontFamily
                    }
                }

                // Kernel
                Row {
                    width: parent.width
                    spacing: 10

                    Text {
                        text: "Kernel"
                        color: Theme.subtext0
                        font.pixelSize: 12
                        font.family: Config.moduleFontFamily
                        width: 80
                    }

                    Text {
                        text: SystemData.kernel
                        color: Theme.text
                        font.pixelSize: 12
                        font.family: Config.moduleFontFamily
                    }
                }

                // Uptime
                Row {
                    width: parent.width
                    spacing: 10

                    Text {
                        text: "Uptime"
                        color: Theme.subtext0
                        font.pixelSize: 12
                        font.family: Config.moduleFontFamily
                        width: 80
                    }

                    Text {
                        text: SystemData.uptime
                        color: Theme.text
                        font.pixelSize: 12
                        font.family: Config.moduleFontFamily
                    }
                }

                // DE/WM
                Row {
                    width: parent.width
                    spacing: 10

                    Text {
                        text: "WM"
                        color: Theme.subtext0
                        font.pixelSize: 12
                        font.family: Config.moduleFontFamily
                        width: 80
                    }

                    Text {
                        text: SystemData.de
                        color: Theme.text
                        font.pixelSize: 12
                        font.family: Config.moduleFontFamily
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.surface0
            }

            // Power Options
            Text {
                text: "Power Options"
                color: Theme.subtext0
                font.pixelSize: 12
                font.family: Config.moduleFontFamily
            }

            Column {
                width: parent.width

                Row {
                    width: parent.width

                 GhostButton {
                        width: parent.width / 2
                    text: "Lock"
                    icon: Icon.lock
                    onClicked: {
                        Process.exec("hyprlock")
                        AppState.toggleMenuOverlay()
                    }
                }

                GhostButton {
                        width: parent.width / 2
                    text: "Logout"
                    icon: Icon.logout
                    onClicked: {
                        Process.exec("hyprctl", "dispatch", "exit")
                        AppState.toggleMenuOverlay()
                    }
                } 
                }

                Row {
                    width: parent.width

                  GhostButton {
                        width: parent.width / 2
                    text: "Reboot"
                    icon: Icon.refresh
                    iconColor: Theme.yellow
                    onClicked: {
                        Process.exec("systemctl", "reboot")
                    }
                }

                GhostButton {
                        width: parent.width / 2
                    text: "Shutdown"
                    icon: Icon.power
                    iconColor: Theme.red
                    onClicked: {
                        Process.exec("systemctl", "poweroff")
                    }
                } 
                }

            }
        }
    }
}
