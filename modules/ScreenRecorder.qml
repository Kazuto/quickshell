import QtQuick
import "root:/"
import "root:/components"

Rectangle {
    implicitWidth: Config.barHeight
    implicitHeight: Config.barHeight
    color: recorderMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    SvgIcon {
        anchors.centerIn: parent
        name: "record"
        size: Config.moduleFontSize
        color: AppState.isRecording ? Theme.red : Theme.overlay1
    }

    MouseArea {
        id: recorderMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { AppState.lastClickX = mapToItem(null, width / 2, 0).x; AppState.toggleScreenRecorderOverlay() }
    }
}
