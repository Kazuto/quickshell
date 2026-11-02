import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

// F3: the volume row. One card per direction for the default device, with the
// others behind its dropdown.
PanelFrame {
    id: panel

    backTo: "control"
    spacing: 8

    Component.onCompleted: AudioData.refreshDevices()

    // Commands only refresh the volume readout, not the per-device list
    Timer {
        id: reloadTimer
        interval: 300
        repeat: false
        onTriggered: AudioData.refreshDevices()
    }

    component DeviceCard: Rectangle {
        id: card

        property var devices: []
        property string defaultName: ""
        property string iconName: ""
        property string mutedIconName: ""
        property bool expanded: false
        signal makeDefault(string name)
        signal toggleMute(string name)
        signal volumeSet(string name, real value)

        readonly property var current: {
            for (var i = 0; i < devices.length; i++) {
                if (devices[i].name === defaultName) return devices[i]
            }
            return devices.length > 0 ? devices[0] : null
        }
        readonly property var others: devices.filter(d => !current || d.name !== current.name)
        readonly property var label: AudioData.deviceLabel(current ? current.description : "")

        width: panel.bodyWidth
        height: column.implicitHeight + 28
        radius: Config.cardRadius
        color: Theme.surfaceLow

        Column {
            id: column
            x: 14
            y: 14
            width: parent.width - 28
            spacing: 8

            Item {
                width: parent.width
                height: 18

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    IslandLabel {
                        width: Math.min(implicitWidth, column.width - 90)
                        text: card.current ? card.label.name : "No device"
                        kind: "island"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    IslandLabel {
                        visible: text !== ""
                        text: card.label.detail
                        kind: "meta"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                SvgIcon {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    name: "caret-down"
                    size: 12
                    color: Theme.text
                    rotation: card.expanded ? 180 : 0

                    Behavior on rotation {
                        NumberAnimation { duration: Config.animationDuration }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.expanded = !card.expanded
                }
            }

            Item {
                visible: card.current !== null
                width: parent.width
                height: 32

                Rectangle {
                    id: muteButton
                    width: 32
                    height: 32
                    radius: 16
                    color: muteMouse.containsMouse ? Theme.surfaceTop : Theme.surfaceHigh

                    SvgIcon {
                        anchors.centerIn: parent
                        name: card.current && card.current.muted ? card.mutedIconName : card.iconName
                        size: 14
                        color: card.current && card.current.muted ? Theme.textFaint : Theme.text
                    }

                    MouseArea {
                        id: muteMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.toggleMute(card.current.name)
                    }
                }

                BarSlider {
                    id: slider
                    anchors.left: muteButton.right
                    anchors.leftMargin: 12
                    anchors.right: amount.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    fillColor: card.current && card.current.muted ? Theme.textFaint : Theme.accent
                    value: card.current ? card.current.volume : 0
                    onCommitted: value => card.volumeSet(card.current.name, value)
                }

                IslandLabel {
                    id: amount
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(slider.shownValue)
                    kind: "meta"
                    color: Theme.text
                }
            }

            Column {
                visible: card.expanded
                width: parent.width

                IslandLabel {
                    visible: card.others.length === 0
                    height: 28
                    text: "No other devices"
                    kind: "meta"
                }

                Repeater {
                    model: card.others

                    delegate: Rectangle {
                        required property var modelData

                        readonly property var label: AudioData.deviceLabel(modelData.description)

                        width: column.width
                        height: 32
                        radius: 8
                        color: otherMouse.containsMouse ? Theme.surfaceHigh : "transparent"

                        IslandLabel {
                            x: 8
                            width: parent.width - 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: label.name + (label.detail !== "" ? " · " + label.detail : "")
                            color: Theme.textDim
                        }

                        MouseArea {
                            id: otherMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                card.expanded = false
                                card.makeDefault(modelData.name)
                            }
                        }
                    }
                }
            }
        }
    }

    headerLeft: [
        IslandLabel {
            text: "Audio"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    IslandLabel { height: 18; text: "Output"; kind: "meta" }

    DeviceCard {
        devices: AudioData.sinks
        defaultName: AudioData.defaultSink
        iconName: "volume"
        mutedIconName: "volume-muted"
        onMakeDefault: name => {
            AudioData.setDefaultSink(name)
            reloadTimer.restart()
        }
        onToggleMute: name => {
            AudioData.toggleSinkMute(name)
            reloadTimer.restart()
        }
        onVolumeSet: (name, value) => AudioData.setSinkVolume(name, Math.round(value))
    }

    IslandLabel { height: 22; verticalAlignment: Text.AlignBottom; text: "Input"; kind: "meta" }

    DeviceCard {
        devices: AudioData.sources
        defaultName: AudioData.defaultSource
        iconName: "microphone"
        mutedIconName: "microphone-muted"
        onMakeDefault: name => {
            AudioData.setDefaultSource(name)
            reloadTimer.restart()
        }
        onToggleMute: name => {
            AudioData.toggleSourceMute(name)
            reloadTimer.restart()
        }
        onVolumeSet: (name, value) => AudioData.setSourceVolume(name, Math.round(value))
    }
}
