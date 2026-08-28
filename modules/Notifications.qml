import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

Rectangle {
    implicitWidth: notifRow.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: notifMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Row {
        id: notifRow
        anchors.centerIn: parent
        spacing: 6

        property int unreadCount: NotificationData.notifications.filter(n => !NotificationData.isRead(n)).length

        SvgIcon {
            name: NotificationData.paused ? "bell-slash" : "bell"
            size: Config.moduleFontSize
            color: NotificationData.paused ? Theme.overlay0 : (notifRow.unreadCount > 0 ? Theme.yellow : Theme.subtext0)
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: notifRow.unreadCount
            color: NotificationData.paused ? Theme.overlay0 : (notifRow.unreadCount > 0 ? Theme.yellow : Theme.subtext0)
            font.pixelSize: Config.moduleFontSize
            font.family: Config.moduleFontFamily
            anchors.verticalCenter: parent.verticalCenter
            visible: notifRow.unreadCount > 0
        }
    }

    MouseArea {
        id: notifMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { AppState.lastClickX = mapToItem(null, width / 2, 0).x; AppState.toggleNotificationsOverlay() }
    }
}
