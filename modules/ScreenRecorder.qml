import QtQuick
import "root:/"

Rectangle {
    implicitWidth: Config.barHeight
    implicitHeight: Config.barHeight
    color: recorderMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    Text {
        id: recorderText
        anchors.centerIn: parent
        text: Icon.record  // Recording circle icon
        color: AppState.isRecording ? Theme.red : Theme.overlay0
        font.pixelSize: Config.moduleFontSize
        font.family: Config.moduleFontFamily
    }

    MouseArea {
        id: recorderMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleScreenRecorderOverlay()
    }
}
