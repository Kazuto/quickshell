import QtQuick
import "root:/"
import "root:/components"

Rectangle {
    implicitWidth: Config.barHeight
    implicitHeight: Config.barHeight
    color: systemStatsMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    SvgIcon {
        id: systemStatsText
        anchors.centerIn: parent
        name: "system-stats"
        size: Config.moduleFontSize
        color: Theme.subtext0
    }

    MouseArea {
        id: systemStatsMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { AppState.lastClickX = mapToItem(null, width / 2, 0).x; AppState.toggleSystemStatsOverlay() }
    }
}
