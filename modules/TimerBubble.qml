import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

// States 05 and 07: the time left, or only the ring when media holds the core
Item {
    id: root

    required property var screen
    property bool ringOnly: false

    implicitWidth: ringOnly ? Config.islandHeight : row.implicitWidth + 2 * 12
    implicitHeight: Config.islandHeight

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.togglePanel("timer", root.screen.name)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        TimerRing {
            progress: TimerData.progress
            ringColor: TimerData.isPaused ? Theme.textDim : Theme.accentSky
            anchors.verticalCenter: parent.verticalCenter
        }

        IslandLabel {
            visible: !root.ringOnly
            text: TimerData.displayTime
            kind: "island"
            color: TimerData.isPaused ? Theme.textDim : Theme.accentSky
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
