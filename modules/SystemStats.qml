import QtQuick
import "root:/"

Rectangle {
    implicitWidth: systemStatsText.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: systemStatsMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Text {
        id: systemStatsText
        anchors.centerIn: parent
        text: Icon.statistics
        color: Theme.sky
        font.pixelSize: Config.moduleFontSize
        font.family: Config.moduleFontFamily
    }

    MouseArea {
        id: systemStatsMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleSystemStatsOverlay()
    }
}
