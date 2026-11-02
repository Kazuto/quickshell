import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

// F2: the Bluetooth tile
PanelFrame {
    id: panel

    backTo: "control"
    spacing: 8

    Component.onCompleted: BluetoothData.updateStatus()

    component DeviceRow: Rectangle {
        id: row

        property var device: null
        property string status: ""
        property string actionLabel: ""
        signal action()

        width: panel.bodyWidth
        height: 52
        radius: Config.cardRadius
        color: Theme.surfaceLow

        SvgIcon {
            id: icon
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            name: BluetoothData.iconFor(row.device)
            size: 16
            color: Theme.text
        }

        Column {
            anchors.left: icon.right
            anchors.leftMargin: 12
            anchors.right: button.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            IslandLabel {
                width: parent.width
                text: row.device.name
                kind: "island"
            }

            IslandLabel {
                text: row.status
                kind: "meta"
            }
        }

        IslandButton {
            id: button
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: 32
            variant: "selected"
            label: row.actionLabel
            onClicked: row.action()
        }
    }

    headerLeft: [
        IslandLabel {
            text: "Bluetooth"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        IslandSwitch {
            checked: BluetoothData.powered
            anchors.verticalCenter: parent.verticalCenter
            onToggled: BluetoothData.togglePower()
        }
    ]

    IslandLabel {
        visible: BluetoothData.powered
        height: 18
        text: "Paired"
        kind: "meta"
    }

    Repeater {
        model: BluetoothData.paired

        delegate: DeviceRow {
            required property var modelData

            device: modelData
            status: modelData.connected ? "connected" : "offline"
            actionLabel: modelData.connected ? "Disconnect" : "Connect"
            onAction: {
                if (modelData.connected) BluetoothData.disconnectDevice(modelData.address)
                else BluetoothData.connectDevice(modelData.address)
            }
        }
    }

    IslandLabel {
        visible: !BluetoothData.powered || BluetoothData.paired.length === 0
        width: parent.width
        height: 44
        horizontalAlignment: Text.AlignHCenter
        text: BluetoothData.powered ? "No paired devices" : "Bluetooth is off"
        kind: "meta"
    }

    IslandLabel {
        visible: BluetoothData.powered && BluetoothData.nearby.length > 0
        height: 18
        text: "Nearby"
        kind: "meta"
    }

    Flickable {
        visible: BluetoothData.powered && BluetoothData.nearby.length > 0
        width: parent.width
        height: Math.min(nearbyList.implicitHeight, 180)
        contentHeight: nearbyList.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: nearbyList
            width: parent.width
            spacing: 8

            Repeater {
                model: BluetoothData.nearby

                delegate: DeviceRow {
                    required property var modelData

                    device: modelData
                    status: "not paired"
                    actionLabel: "Pair"
                    onAction: BluetoothData.pairDevice(modelData.address)
                }
            }
        }
    }

    Item {
        visible: BluetoothData.powered
        width: 1
        height: 4
    }

    IslandButton {
        visible: BluetoothData.powered
        width: parent.width
        iconName: "search"
        iconSize: 14
        active: !BluetoothData.scanning
        label: BluetoothData.scanning ? "Scanning…" : "Scan for devices"
        onClicked: BluetoothData.scan()
    }
}
