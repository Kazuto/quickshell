import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

Rectangle {
    id: root
    implicitWidth: Config.barHeight
    implicitHeight: Config.barHeight
    color: vpnMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    SvgIcon {
        id: vpnText
        anchors.centerIn: parent
        name: "vpn"
        size: Config.moduleFontSize
        color: VpnData.connected ? Theme.green : Theme.overlay0
        opacity: VpnData.busy ? 0.5 : 1.0
    }

    MouseArea {
        id: vpnMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { AppState.lastClickX = mapToItem(null, width / 2, 0).x; AppState.toggleVpnOverlay() }
    }
}
