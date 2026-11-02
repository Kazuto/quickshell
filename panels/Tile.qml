import QtQuick
import "root:/"
import "root:/components"

// Control center quick setting. Filled with the accent while on.
Rectangle {
    id: tile

    property string iconName: ""
    property string title: ""
    property string subtitle: ""
    property color subtitleColor: Theme.textDim
    property bool lit: false
    signal clicked()
    signal rightClicked()

    readonly property color contentColor: lit ? Theme.textOnAccent : Theme.text

    width: (parent.width - parent.spacing) / 2
    height: 56
    radius: Config.cardRadius
    color: lit ? Theme.accent : tileMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceLow

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    SvgIcon {
        id: icon
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        name: tile.iconName
        size: 18
        color: tile.contentColor
    }

    Column {
        anchors.left: icon.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        IslandLabel {
            width: parent.width
            text: tile.title
            kind: "island"
            color: tile.contentColor
        }

        IslandLabel {
            width: parent.width
            text: tile.subtitle
            kind: "meta"
            color: tile.lit ? Theme.textOnAccent : tile.subtitleColor
        }
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) tile.rightClicked()
            else tile.clicked()
        }
    }
}
