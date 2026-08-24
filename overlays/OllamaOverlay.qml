import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/singletons"
import "root:/components"

PanelWindow {
    id: ollamaOverlay

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
            OllamaData.refresh()
        }
    }

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: AppState.toggleOllamaOverlay()
        z: -1
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 12
            rightMargin: 20
        }
        width: 400
        height: Math.min(600, parent.height - Config.barHeight - Config.barMarginTop - 40)
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
            spacing: 15

            // Header
            Item {
                width: parent.width
                height: 30

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Icon.ollama + " Ollama"
                    color: Theme.text
                    font.pixelSize: 18
                    font.bold: true
                    font.family: Config.moduleFontFamily
                }

                // Status indicator
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: OllamaData.isRunning ? Theme.green : Theme.red
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: OllamaData.isRunning ? "Running" : "Stopped"
                        color: Theme.subtext0
                        font.pixelSize: 12
                        font.family: Config.moduleFontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.surface0
            }

            // Loaded model indicator
            Rectangle {
                width: parent.width
                height: 35
                radius: 8
                color: Theme.surface0
                visible: OllamaData.loadedModel.length > 0

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "⚡"
                        color: Theme.yellow
                        font.pixelSize: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Loaded: " + OllamaData.loadedModel
                        color: Theme.text
                        font.pixelSize: 13
                        font.family: Config.moduleFontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Models header
            Row {
                width: parent.width
                spacing: 10

                Text {
                    text: "Models (" + OllamaData.models.length + ")"
                    color: Theme.subtext0
                    font.pixelSize: 12
                    font.family: Config.moduleFontFamily
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: parent.width - 200 }

                // Refresh button
                GhostButton {
                    width: 28
                    height: 28
                    radius: 14
                    icon: Icon.refresh
                    iconSize: 14
                    text: ""
                    onClicked: OllamaData.refresh()
                }
            }

            // Models list
            ScrollView {
                width: parent.width
                height: parent.height - 180
                clip: true

                Column {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: OllamaData.models

                        Rectangle {
                            width: parent.width
                            height: 60
                            radius: 8
                            color: modelData.name === OllamaData.loadedModel ? Config.alpha(Theme.green, 0.1) : Theme.surface0
                            border.color: modelData.name === OllamaData.loadedModel ? Theme.green : Theme.surface1
                            border.width: 1

                            Column {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 15
                                    rightMargin: 15
                                }
                                spacing: 4

                                Text {
                                    text: modelData.name
                                    color: Theme.text
                                    font.pixelSize: 14
                                    font.bold: modelData.name === OllamaData.loadedModel
                                    font.family: Config.moduleFontFamily
                                }

                                Text {
                                    text: modelData.size
                                    color: Theme.subtext0
                                    font.pixelSize: 11
                                    font.family: Config.moduleFontFamily
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    // Could implement model loading here
                                    console.log("Selected model:", modelData.name)
                                }
                            }
                        }
                    }

                    // Empty state
                    Item {
                        width: parent.width
                        height: 100
                        visible: OllamaData.models.length === 0

                        Text {
                            anchors.centerIn: parent
                            text: OllamaData.isRunning ? "No models installed" : "Ollama not running"
                            color: Theme.overlay1
                            font.pixelSize: 13
                            font.family: Config.moduleFontFamily
                        }
                    }
                }
            }
        }
    }
}
