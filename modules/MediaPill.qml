import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

// States 02 and 07: the playing track borrows the core. With a bubble beside it
// the artist drops out to keep the group from sprawling.
Item {
    id: root

    required property var screen
    property bool shrunk: false

    readonly property int cornerRadius: Config.islandHeight / 2

    implicitWidth: row.implicitWidth + 6 + 14
    implicitHeight: Config.islandHeight

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => AppState.togglePanel(
            mouse.button === Qt.RightButton ? "control" : "media", root.screen.name)
        onWheel: wheel => OsdData.showVolume(
            AudioData.stepOutputVolume(wheel.angleDelta.y > 0 ? 5 : -5), false)
    }

    Row {
        id: row
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        IconDisc {
            iconName: "disc"
            anchors.verticalCenter: parent.verticalCenter
        }

        IslandLabel {
            width: Math.min(implicitWidth, 240)
            text: MediaData.title
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        }

        IslandLabel {
            visible: !root.shrunk && text !== ""
            width: Math.min(implicitWidth, 180)
            text: MediaData.artist
            color: Theme.textDim
            anchors.verticalCenter: parent.verticalCenter
        }

        EqBars {
            playing: MediaData.isPlaying
            anchors.verticalCenter: parent.verticalCenter
        }

        IslandLabel {
            text: IslandData.clockText
            color: Theme.textDim
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
