import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

// State 04: volume or brightness, held for 1.5 s and reset by further input
Item {
    id: root

    required property var screen

    readonly property int cornerRadius: Config.islandHeight / 2
    readonly property bool muted: OsdData.type === "mute"

    implicitWidth: 266
    implicitHeight: Config.islandHeight

    MouseArea {
        anchors.fill: parent
        onWheel: wheel => OsdData.showVolume(
            AudioData.stepOutputVolume(wheel.angleDelta.y > 0 ? 5 : -5), false)
    }

    SvgIcon {
        id: icon
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        name: OsdData.type === "brightness" ? "sun" : root.muted ? "volume-muted" : "volume"
        size: 14
        color: Theme.textDim
    }

    BarSlider {
        anchors.left: icon.right
        anchors.leftMargin: 12
        anchors.right: value.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        interactive: false
        thickness: 6
        value: root.muted ? 0 : OsdData.value
    }

    IslandLabel {
        id: value
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        horizontalAlignment: Text.AlignRight
        text: root.muted ? "–" : OsdData.value
        kind: "island"
    }
}
