import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/singletons"
import "root:/components"

PanelWindow {
    id: timerOverlay

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
        onClicked: AppState.toggleTimerOverlay()
        z: -1
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 12
            rightMargin: 20
        }
        width: 350
        height: 480
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
                text: Icon.clock + " Timer"
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

            // Timer display
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: TimerData.displayTime
                color: TimerData.remainingSeconds < 0 ? Theme.red : (TimerData.running ? Theme.yellow : Theme.text)
                font.pixelSize: 48
                font.bold: true
                font.family: Config.moduleFontFamily
            }

            // Progress indicator
            Rectangle {
                width: parent.width
                height: 8
                radius: 4
                color: Theme.surface0

                Rectangle {
                    width: TimerData.totalSeconds > 0 ?
                           parent.width * Math.max(0, Math.min(1, TimerData.remainingSeconds / TimerData.totalSeconds)) : 0
                    height: parent.height
                    radius: parent.radius
                    color: TimerData.remainingSeconds < 0 ? Theme.red : Theme.yellow
                }
            }

            // Control buttons (only show when timer is running)
            Item {
                width: parent.width
                height: 45
                visible: TimerData.running

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 270
                    height: 45
                    radius: 8
                    color: Theme.surface0
                    border.color: Theme.surface2
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        spacing: 0

                        // Pause/Resume button (rounded left)
                        Item {
                            width: 90
                            height: parent.height
                            clip: true

                            Rectangle {
                                anchors.fill: parent
                                anchors.rightMargin: -8
                                color: startPauseMouseArea.containsMouse ? Theme.surface1 : "transparent"
                                radius: 8
                            }

                            MouseArea {
                                id: startPauseMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (TimerData.isPaused) {
                                        TimerData.resume()
                                    } else {
                                        TimerData.pause()
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: TimerData.isPaused ? "▶" : "⏸"
                                color: Theme.text
                                font.pixelSize: 18
                                font.family: Config.moduleFontFamily
                                z: 1
                            }
                        }

                        // Separator
                        Rectangle {
                            width: 1
                            height: parent.height - 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.surface2
                        }

                        // Reset button (no rounded corners)
                        Rectangle {
                            width: 89
                            height: parent.height
                            color: resetMouseArea.containsMouse ? Theme.surface1 : "transparent"
                            radius: 0

                            MouseArea {
                                id: resetMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: TimerData.reset()
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "↻"
                                color: Theme.text
                                font.pixelSize: 20
                                font.family: Config.moduleFontFamily
                                z: 1
                            }
                        }

                        // Separator
                        Rectangle {
                            width: 1
                            height: parent.height - 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.surface2
                        }

                        // Stop button (rounded right)
                        Item {
                            width: 90
                            height: parent.height
                            clip: true

                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: -8
                                color: stopMouseArea.containsMouse ? Theme.surface1 : "transparent"
                                radius: 8
                            }

                            MouseArea {
                                id: stopMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: TimerData.stop()
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "⏹"
                                color: Theme.red
                                font.pixelSize: 18
                                font.family: Config.moduleFontFamily
                                z: 1
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.surface0
            }

            // Preset buttons
            Text {
                text: "Quick Start"
                color: Theme.subtext0
                font.pixelSize: 12
                font.family: Config.moduleFontFamily
            }

            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 3
                spacing: 10

                Repeater {
                    model: [1, 5, 10, 15, 25, 30]

                    GhostButton {
                        width: 95
                        height: 40
                        text: modelData + " min"
                        onClicked: {
                            TimerData.start(modelData)
                        }
                    }
                }
            }
        }
    }
}
