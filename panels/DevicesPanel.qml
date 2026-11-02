import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

// F6: the devices chip
PanelFrame {
    id: panel

    backTo: "control"
    spacing: 12

    Component.onCompleted: LogitechData.refresh()

    headerLeft: [
        IslandLabel {
            text: "Devices"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        IslandButton {
            implicitHeight: 28
            iconName: "refresh"
            iconSize: 12
            anchors.verticalCenter: parent.verticalCenter
            onClicked: LogitechData.refresh()
        }
    ]

    Repeater {
        model: LogitechData.devices

        delegate: Rectangle {
            id: card

            required property var modelData

            readonly property bool hasLevel: modelData.connected && modelData.level >= 0
            readonly property bool low: hasLevel && modelData.level <= LogitechData.lowBatteryThreshold

            width: panel.bodyWidth
            height: column.implicitHeight + 24
            radius: Config.cardRadius
            color: Theme.surfaceLow

            Column {
                id: column
                x: 14
                y: 12
                width: parent.width - 28
                spacing: 8

                Item {
                    width: parent.width
                    height: 32

                    SvgIcon {
                        id: icon
                        anchors.verticalCenter: parent.verticalCenter
                        name: card.modelData.kind === "mouse" ? "mouse" : "keyboard"
                        size: 16
                        color: card.modelData.connected ? Theme.text : Theme.textDim
                    }

                    Column {
                        anchors.left: icon.right
                        anchors.leftMargin: 12
                        anchors.right: amount.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        IslandLabel {
                            width: parent.width
                            text: card.modelData.name
                            kind: "island"
                        }

                        IslandLabel {
                            text: card.modelData.kind + " · " + (card.modelData.connected ? "openlogi" : "offline")
                            kind: "meta"
                        }
                    }

                    IslandLabel {
                        id: amount
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: card.hasLevel ? card.modelData.level + "%" : "–"
                        kind: card.low ? "island" : "meta"
                        color: card.low ? Theme.warn : Theme.textDim
                    }
                }

                BarSlider {
                    visible: card.hasLevel
                    width: parent.width
                    interactive: false
                    thickness: 6
                    fillColor: card.low ? Theme.warn : Theme.accentSky
                    value: Math.max(3, card.modelData.level)
                }
            }
        }
    }

    IslandLabel {
        visible: LogitechData.devices.length === 0
        width: parent.width
        height: 56
        horizontalAlignment: Text.AlignHCenter
        text: "No devices found"
        kind: "meta"
    }
}
