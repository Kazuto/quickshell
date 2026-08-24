import QtQuick
import "root:/"

Rectangle {
    implicitWidth: controlCenterText.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: controlCenterMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Text {
        id: controlCenterText
        anchors.centerIn: parent
        text: Icon.sliders  // Grid icon for control center
        color: Theme.peach
        font.pixelSize: Config.moduleFontSize
        font.family: Config.moduleFontFamily
    }

    MouseArea {
        id: controlCenterMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleControlCenterOverlay()
    }
}
