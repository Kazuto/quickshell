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

        SvgIcon {
            name: NotificationData.paused ? "bell-slash" : "bell"
            size: Config.moduleFontSize
            color: NotificationData.paused ? Theme.overlay0 : (NotificationData.count > 0 ? Theme.yellow : Theme.subtext0)
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: NotificationData.count
            color: NotificationData.paused ? Theme.overlay0 : (NotificationData.count > 0 ? Theme.yellow : Theme.subtext0)
            font.pixelSize: Config.moduleFontSize
            font.family: Config.moduleFontFamily
            anchors.verticalCenter: parent.verticalCenter
            visible: NotificationData.count > 0
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
