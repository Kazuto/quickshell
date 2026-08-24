import QtQuick
import "root:/"

Rectangle {
    implicitWidth: Config.barHeight  // Square (1:1 aspect ratio)
    implicitHeight: Config.barHeight
    color: menuMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    Text {
        id: menuText
        anchors.centerIn: parent
        text: Icon.ubuntu
        color: Theme.blue 
        font.pixelSize: Config.moduleFontSize
        font.family: Config.moduleFontFamily
    }

    MouseArea {
        id: menuMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleMenuOverlay()
    }
}
