import QtQuick
import "root:/"
import "root:/components"

Rectangle {
    implicitWidth: Config.barHeight
    implicitHeight: Config.barHeight
    color: controlCenterMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    SvgIcon {
        id: controlCenterText
        anchors.centerIn: parent
        name: "control-center"
        size: Config.moduleFontSize
        color: Theme.peach
    }

    MouseArea {
        id: controlCenterMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleControlCenterOverlay()
    }
}
