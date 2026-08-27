import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

Rectangle {
    implicitWidth: Config.barHeight
    implicitHeight: Config.barHeight
    color: wifiMouse.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Behavior on color { ColorAnimation { duration: Config.animationDuration } }

    SvgIcon {
        anchors.centerIn: parent
        name: WifiData.enabled ? "wifi" : "wifi-off"
        size: Config.moduleFontSize
        color: WifiData.enabled ? Theme.subtext0 : Theme.overlay0
    }

    MouseArea {
        id: wifiMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { AppState.lastClickX = mapToItem(null, width / 2, 0).x; AppState.toggleWifiOverlay() }
    }
}
