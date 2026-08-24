import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

Rectangle {
    implicitWidth: bluetoothRow.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: bluetoothMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Row {
        id: bluetoothRow
        anchors.centerIn: parent
        spacing: 6

        SvgIcon {
            name: "bluetooth"
            size: Config.moduleFontSize
            color: BluetoothData.powered ? Theme.sky : Theme.overlay0
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: {
                if (!BluetoothData.powered) return "Off"
                if (BluetoothData.connectedDevice) return BluetoothData.connectedDevice
                return "On"
            }
            color: BluetoothData.powered ? Theme.sky : Theme.overlay0
            font.pixelSize: Config.moduleFontSize
            font.family: Config.moduleFontFamily
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: bluetoothMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleBluetoothOverlay()
    }
}
