import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/singletons"

PanelWindow {
    id: audioOverlay

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
            AudioData.refreshDevices()
        }
    }

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: AppState.toggleAudioOverlay()
        z: -1
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 12
            rightMargin: 50  // Position overlay near Audio module
        }
        width: 400
        height: contentColumn.implicitHeight + 40
        color: Config.alpha(Theme.base, 0.95)
        radius: Config.overlayRadius
        border.color: Theme.surface0
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: {} // Prevent clicks from passing through
        }

        Column {
            id: contentColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 20
            }
            spacing: 20

            // Output Devices Section
            Column {
                width: parent.width
                spacing: 15

                Text {
                    text: "Output Devices"
                    color: Theme.text
                    font.pixelSize: 16
                    font.bold: true
                    font.family: Config.moduleFontFamily
                }

                Repeater {
                    model: AudioData.sinks

                    Column {
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            width: parent.width
                            height: 60
                            color: AudioData.defaultSink === modelData.name ? Theme.surface1 : Theme.surface0
                            radius: Config.moduleRadius

                            Column {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    margins: 15
                                }
                                spacing: 8

                                Row {
                                    width: parent.width
                                    spacing: 10

                                    Text {
                                        text: modelData.muted ? Icon.volumeMuted : Icon.volume
                                        color: modelData.muted ? Theme.overlay0 : Theme.mauve
                                        font.pixelSize: 18
                                        font.family: Config.moduleFontFamily
                                    }

                                    Text {
                                        width: parent.width - 100
                                        text: modelData.description
                                        color: AudioData.defaultSink === modelData.name ? Theme.green : Theme.text
                                        font.pixelSize: 13
                                        font.family: Config.moduleFontFamily
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        id: volumeLabel
                                        text: volumeSlider.value.toFixed(0) + "%"
                                        color: Theme.subtext0
                                        font.pixelSize: 12
                                        font.family: Config.moduleFontFamily
                                    }
                                }

                                Slider {
                                    id: volumeSlider
                                    width: parent.width
                                    from: 0
                                    to: 100
                                    value: modelData.volume
                                    stepSize: 1

                                    onPressedChanged: {
                                        if (!pressed) {
                                            AudioData.setSinkVolume(modelData.name, value)
                                        }
                                    }

                                    background: Rectangle {
                                        x: parent.leftPadding
                                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                        implicitWidth: 200
                                        implicitHeight: 4
                                        width: parent.availableWidth
                                        height: implicitHeight
                                        radius: 2
                                        color: Theme.surface2

                                        Rectangle {
                                            width: parent.parent.visualPosition * parent.width
                                            height: parent.height
                                            color: Theme.mauve
                                            radius: 2
                                        }
                                    }

                                    handle: Rectangle {
                                        x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                        implicitWidth: 16
                                        implicitHeight: 16
                                        radius: 8
                                        color: Theme.mauve
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                onClicked: {
                                    if (AudioData.defaultSink !== modelData.name) {
                                        AudioData.setDefaultSink(modelData.name)
                                    } else {
                                        AudioData.toggleSinkMute(modelData.name)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.surface0
            }

            // Input Devices Section
            Column {
                width: parent.width
                spacing: 15

                Text {
                    text: "Input Devices"
                    color: Theme.text
                    font.pixelSize: 16
                    font.bold: true
                    font.family: Config.moduleFontFamily
                }

                Repeater {
                    model: AudioData.sources

                    Column {
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            width: parent.width
                            height: 60
                            color: AudioData.defaultSource === modelData.name ? Theme.surface1 : Theme.surface0
                            radius: Config.moduleRadius

                            Column {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    margins: 15
                                }
                                spacing: 8

                                Row {
                                    width: parent.width
                                    spacing: 10

                                    Text {
                                        text: modelData.muted ? Icon.microphoneMuted : Icon.microphone
                                        color: modelData.muted ? Theme.overlay0 : Theme.mauve
                                        font.pixelSize: 18
                                        font.family: Config.moduleFontFamily
                                    }

                                    Text {
                                        width: parent.width - 100
                                        text: modelData.description
                                        color: AudioData.defaultSource === modelData.name ? Theme.green : Theme.text
                                        font.pixelSize: 13
                                        font.family: Config.moduleFontFamily
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        id: inputVolumeLabel
                                        text: inputVolumeSlider.value.toFixed(0) + "%"
                                        color: Theme.subtext0
                                        font.pixelSize: 12
                                        font.family: Config.moduleFontFamily
                                    }
                                }

                                Slider {
                                    id: inputVolumeSlider
                                    width: parent.width
                                    from: 0
                                    to: 100
                                    value: modelData.volume
                                    stepSize: 1

                                    onPressedChanged: {
                                        if (!pressed) {
                                            AudioData.setSourceVolume(modelData.name, value)
                                        }
                                    }

                                    background: Rectangle {
                                        x: parent.leftPadding
                                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                        implicitWidth: 200
                                        implicitHeight: 4
                                        width: parent.availableWidth
                                        height: implicitHeight
                                        radius: 2
                                        color: Theme.surface2

                                        Rectangle {
                                            width: parent.parent.visualPosition * parent.width
                                            height: parent.height
                                            color: Theme.mauve
                                            radius: 2
                                        }
                                    }

                                    handle: Rectangle {
                                        x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                        implicitWidth: 16
                                        implicitHeight: 16
                                        radius: 8
                                        color: Theme.mauve
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                onClicked: {
                                    if (AudioData.defaultSource !== modelData.name) {
                                        AudioData.setDefaultSource(modelData.name)
                                    } else {
                                        AudioData.toggleSourceMute(modelData.name)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
