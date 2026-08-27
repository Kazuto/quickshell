import QtQuick
import "root:/"

Rectangle {
    implicitWidth: Config.barHeight
    implicitHeight: Config.barHeight
    color: menuMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    Text {
        anchors.centerIn: parent
        text: Icon.ubuntu
        color: Theme.subtext0
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
