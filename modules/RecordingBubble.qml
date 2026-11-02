import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

// State 06: recording keeps a left bubble for as long as it runs
Item {
    id: root

    required property var screen

    implicitWidth: row.implicitWidth + 16 + 4
    implicitHeight: Config.islandHeight

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.togglePanel("recorder", root.screen.name)
    }

    Row {
        id: row
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: Theme.rec
            anchors.verticalCenter: parent.verticalCenter

            SequentialAnimation on opacity {
                running: RecorderData.recording
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
            }
        }

        IslandLabel {
            text: "REC " + RecorderData.elapsedText
            kind: "island"
            color: Theme.rec
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 28
            height: 28
            radius: 14
            color: stopMouse.containsMouse ? Theme.surfaceTop : Theme.surfaceHigh
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: 2
                color: Theme.text
            }

            MouseArea {
                id: stopMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: RecorderData.stop()
            }
        }
    }
}
