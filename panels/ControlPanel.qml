import QtQuick
import Quickshell
import "root:/"
import "root:/singletons"
import "root:/components"
import "root:/modules" as Modules

// F: click the right wing. Tiles open their detail on click; ones that can be
// switched directly toggle on right-click.
PanelFrame {
    id: panel

    required property var screen

    spacing: 12

    Component.onCompleted: {
        BrightnessData.refresh()
        WifiData.refresh()
        BluetoothData.updateStatus()
    }

    function openDetail(name) {
        AppState.openPanel(name, panel.screen.name)
    }

    readonly property int connectedBluetooth: {
        var count = 0
        for (var i = 0; i < BluetoothData.devices.length; i++)
            if (BluetoothData.devices[i].connected) count++
        return count
    }

    headerLeft: [
        IslandLabel {
            text: "Control center"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        Rectangle {
            width: userRow.implicitWidth + 20
            height: 28
            radius: 14
            color: userMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceLow
            anchors.verticalCenter: parent.verticalCenter

            Row {
                id: userRow
                anchors.centerIn: parent
                spacing: 6

                IslandLabel {
                    text: Quickshell.env("USER") + "@hypr"
                    kind: "meta"
                    anchors.verticalCenter: parent.verticalCenter
                }

                SvgIcon {
                    name: "caret-right"
                    size: 10
                    color: Theme.textDim
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: userMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: panel.openDetail("system")
            }
        }
    ]

    Grid {
        width: parent.width
        columns: 2
        spacing: 8

        Tile {
            iconName: WifiData.wiredConnected && WifiData.connectedSsid === "" ? "network" : WifiData.enabled ? "wifi" : "wifi-off"
            title: "Network"
            subtitle: WifiData.connectedSsid
                || (WifiData.wiredConnected ? "Ethernet" : WifiData.enabled ? "Not connected" : "Off")
            lit: WifiData.connectedSsid !== "" || WifiData.wiredConnected
            onClicked: panel.openDetail("network")
            onRightClicked: WifiData.toggleWifi()
        }

        Tile {
            iconName: "bluetooth"
            title: "Bluetooth"
            subtitle: panel.connectedBluetooth > 1 ? panel.connectedBluetooth + " devices"
                : BluetoothData.connectedDevice || (BluetoothData.powered ? "On" : "Off")
            lit: BluetoothData.powered
            onClicked: panel.openDetail("bluetooth")
            onRightClicked: BluetoothData.togglePower()
        }

        Tile {
            iconName: "coffee"
            title: "Caffeine"
            subtitle: CaffeineData.active ? "keeping awake" : "off"
            lit: CaffeineData.active
            onClicked: CaffeineData.toggle()
        }

        Tile {
            iconName: "record"
            title: "Record"
            subtitle: RecorderData.recording ? "REC " + RecorderData.elapsedText : "opens recorder"
            lit: RecorderData.recording
            onClicked: AppState.openPanel("recorder", panel.screen.name)
        }

        Tile {
            iconName: "shield"
            title: "VPN"
            subtitle: VpnData.busy ? "…" : VpnData.connected ? VpnData.connectionName : "off"
            lit: VpnData.connected
            onClicked: panel.openDetail("vpn")
            onRightClicked: VpnData.toggle()
        }

        Tile {
            iconName: "pulse"
            title: "Monitor"
            subtitle: "CPU " + SystemStatsData.cpuTemp + "°C"
            subtitleColor: SystemStatsData.cpuTemp >= 85 ? Theme.warn : Theme.textDim
            onClicked: panel.openDetail("monitor")
        }
    }

    Column {
        width: parent.width
        spacing: 4

        Row {
            width: parent.width
            spacing: 12

            SvgIcon {
                name: AudioData.outputMuted ? "volume-muted" : "volume"
                size: 16
                color: Theme.text
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) AudioData.toggleOutputMute()
                        else panel.openDetail("audio")
                    }
                }
            }

            BarSlider {
                width: parent.width - 16 - 28 - 2 * parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                value: AudioData.outputMuted ? 0 : AudioData.outputVolume
                onMoved: value => {
                    AudioData.outputVolume = Math.round(value)
                    AudioData.setOutputVolume(value)
                }
            }

            IslandLabel {
                width: 28
                horizontalAlignment: Text.AlignRight
                text: AudioData.outputMuted ? "–" : AudioData.outputVolume
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.openDetail("audio")
                }
            }
        }

        Row {
            visible: BrightnessData.available
            width: parent.width
            spacing: 12

            SvgIcon {
                name: "sun"
                size: 16
                color: Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }

            BarSlider {
                width: parent.width - 16 - 28 - 2 * parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                fillColor: Theme.textDim
                value: BrightnessData.level
                onMoved: value => BrightnessData.set(value)
            }

            IslandLabel {
                width: 28
                horizontalAlignment: Text.AlignRight
                text: BrightnessData.level
                color: Theme.textDim
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 40
        radius: 20
        color: deviceMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceLow

        Row {
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            IslandLabel {
                text: "Devices"
                kind: "meta"
                anchors.verticalCenter: parent.verticalCenter
            }

            SvgIcon {
                name: "mouse"
                size: 16
                color: Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }

            IslandLabel {
                text: LogitechData.deviceName
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        IslandLabel {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            visible: LogitechData.level >= 0
            text: LogitechData.level + "%"
            kind: LogitechData.low ? "island" : "body"
            color: LogitechData.low ? Theme.warn : Theme.textDim
        }

        MouseArea {
            id: deviceMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: panel.openDetail("devices")
        }
    }

    Rectangle {
        visible: BatteryData.present
        width: parent.width
        height: 44
        radius: 22
        color: batteryMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceLow

        Row {
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            SvgIcon {
                name: BatteryData.iconName
                size: 16
                color: BatteryData.isLow ? Theme.warn : Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }

            IslandLabel {
                text: BatteryData.profileLabel !== "" ? "Battery · " + BatteryData.profileLabel : "Battery"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            BarSlider {
                width: 56
                interactive: false
                thickness: 6
                fillColor: BatteryData.isLow ? Theme.warn : Theme.accentSky
                value: BatteryData.capacity
                anchors.verticalCenter: parent.verticalCenter
            }

            IslandLabel {
                text: BatteryData.capacity + "%"
                color: Theme.textDim
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: batteryMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: panel.openDetail("battery")
        }
    }

    Rectangle {
        visible: tray.itemCount > 0
        width: parent.width
        height: 40
        radius: 20
        color: Theme.surfaceLow

        IslandLabel {
            x: 16
            width: parent.width - tray.width - 32
            anchors.verticalCenter: parent.verticalCenter
            text: tray.hoveredLabel !== "" ? tray.hoveredLabel : "Tray"
            kind: "meta"
        }

        Modules.Tray {
            id: tray
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            screen: panel.screen
        }
    }
}
