import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "root:/"
import "root:/singletons"
import "root:/components"

PanelWindow {
    id: powerOverlay

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusiveZone: -1

    function run(cmd) {
        Qt.createQmlObject(
            'import Quickshell.Io; Process { command: ' + JSON.stringify(cmd) + '; running: true }',
            powerOverlay
        )
    }

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: AppState.togglePowerOverlay()
        z: -1
    }

    // Full-screen blurred backdrop
    Rectangle {
        anchors.fill: parent
        color: Config.alpha(Theme.base, 0.85)

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Column {
            anchors.centerIn: parent
            spacing: 48

            // Title
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Power Menu"
                color: Theme.subtext0
                font.pixelSize: 14
                font.family: Config.moduleFontFamily
                font.letterSpacing: 3
            }

            // Buttons row
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24

                // Lock
                PowerButton {
                    label: "Lock"
                    keyHint: "L"
                    icon: "lock"
                    accentColor: Theme.yellow
                    onActivated: {
                        run(["hyprlock"])
                        AppState.togglePowerOverlay()
                    }
                }

                // Logout
                PowerButton {
                    label: "Logout"
                    keyHint: "E"
                    icon: "logout"
                    accentColor: Theme.peach
                    onActivated: {
                        run(["killall", "Hyprland"])
                        AppState.togglePowerOverlay()
                    }
                }

                // Reboot
                PowerButton {
                    label: "Reboot"
                    keyHint: "R"
                    icon: "refresh"
                    accentColor: Theme.green
                    onActivated: {
                        run(["systemctl", "reboot"])
                    }
                }

                // Shutdown
                PowerButton {
                    label: "Shutdown"
                    keyHint: "S"
                    icon: "power"
                    accentColor: Theme.red
                    onActivated: {
                        run(["systemctl", "poweroff"])
                    }
                }

                // Suspend
                PowerButton {
                    label: "Suspend"
                    keyHint: "U"
                    icon: "suspend"
                    accentColor: Theme.lavender
                    onActivated: {
                        run(["systemctl", "suspend"])
                        AppState.togglePowerOverlay()
                    }
                }
            }

            // Hint
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Press Esc to cancel"
                color: Theme.overlay0
                font.pixelSize: 12
                font.family: Config.moduleFontFamily
            }
        }

        // Keyboard shortcuts
        Item {
            focus: true
            Keys.onPressed: event => {
                switch (event.key) {
                    case Qt.Key_L:
                        run(["hyprlock"])
                        AppState.togglePowerOverlay()
                        break
                    case Qt.Key_E:
                        run(["killall", "Hyprland"])
                        AppState.togglePowerOverlay()
                        break
                    case Qt.Key_R:
                        run(["systemctl", "reboot"])
                        break
                    case Qt.Key_S:
                        run(["systemctl", "poweroff"])
                        break
                    case Qt.Key_U:
                        run(["systemctl", "suspend"])
                        AppState.togglePowerOverlay()
                        break
                    case Qt.Key_Escape:
                        AppState.togglePowerOverlay()
                        break
                }
            }
        }
    }
}
