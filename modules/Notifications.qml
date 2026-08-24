import QtQuick
import "root:/"
import "root:/singletons"

Rectangle {
    implicitWidth: notifText.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: notifMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Text {
        id: notifText
        anchors.centerIn: parent
        text: "󰂚 " + NotificationData.count
        color: NotificationData.paused ? Theme.overlay0 : (NotificationData.count > 0 ? Theme.yellow : Theme.overlay0)
        font.pixelSize: Config.moduleFontSize
        font.family: Config.moduleFontFamily
    }

    MouseArea {
        id: notifMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleNotificationsOverlay()
    }
}
