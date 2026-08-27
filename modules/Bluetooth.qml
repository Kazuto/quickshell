import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

Rectangle {
    implicitWidth: Config.barHeight
    implicitHeight: Config.barHeight
    color: bluetoothMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    SvgIcon {
        anchors.centerIn: parent
        name: "bluetooth"
        size: Config.moduleFontSize
        color: BluetoothData.powered ? Theme.subtext0 : Theme.overlay0
    }

    MouseArea {
        id: bluetoothMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { AppState.lastClickX = mapToItem(null, width / 2, 0).x; AppState.toggleBluetoothOverlay() }
    }
}
