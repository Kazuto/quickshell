import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

Rectangle {
    implicitWidth: audioRow.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: audioMouse.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Behavior on color { ColorAnimation { duration: Config.animationDuration } }

    Row {
        id: audioRow
        anchors.centerIn: parent
        spacing: 6

        SvgIcon {
            name: AudioData.outputMuted ? "volume-muted" : "volume"
            size: Config.moduleFontSize
            color: AudioData.outputMuted ? Theme.overlay0 : Theme.subtext0
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: AudioData.outputMuted ? "Muted" : AudioData.outputVolume + "%"
            color: AudioData.outputMuted ? Theme.overlay0 : Theme.subtext0
            font.pixelSize: Config.moduleFontSize
            font.family: Config.moduleFontFamily
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: audioMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            AppState.lastClickX = mapToItem(null, width / 2, 0).x
            if (mouse.button === Qt.RightButton) AudioData.toggleOutputMute()
            else AppState.toggleAudioOverlay()
        }
    }
}
