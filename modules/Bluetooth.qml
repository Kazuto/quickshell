import QtQuick
import "root:/"
import "root:/singletons"

Rectangle {
    implicitWidth: bluetoothText.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: bluetoothMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Text {
        id: bluetoothText
        anchors.centerIn: parent
        text: {
            if (!BluetoothData.powered) {
                return Icon.bluetooth + " Off"
            } else if (BluetoothData.connectedDevice) {
                return Icon.bluetooth + " " + BluetoothData.connectedDevice
            } else {
                return Icon.bluetooth + " On"
            }
        }
        color: BluetoothData.powered ? Theme.sky : Theme.overlay0
        font.pixelSize: Config.moduleFontSize
        font.family: Config.moduleFontFamily
    }

    MouseArea {
        id: bluetoothMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            AppState.toggleBluetoothOverlay()
        }
    }
}
