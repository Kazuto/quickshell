import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/singletons"
import "root:/components"

PanelWindow {
    id: controlCenterOverlay

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: AppState.toggleControlCenterOverlay()
        z: -1
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 12
            rightMargin: 20
        }
        height: AppState.controlCenterView === "main" ? mainView.implicitHeight + 40 : Math.min(500, parent.height - Config.barHeight - 50)
        width: 350
        color: Config.alpha(Theme.base, 0.95)
        radius: Config.overlayRadius
        border.color: Theme.surface0
        border.width: 1

        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // Main view - quick controls
        Column {
            id: mainView
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 20
            }
            spacing: 12
            visible: AppState.controlCenterView === "main"

            // Bluetooth quick tile
            Rectangle {
                width: parent.width
                height: 70
                color: btMouseArea.containsMouse ? Theme.surface1 : Theme.surface0
                radius: Config.moduleRadius

                Row {
                    anchors {
                        fill: parent
                        margins: 15
                    }
                    spacing: 15

                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: BluetoothData.powered ? Theme.sky : Theme.surface2
                        anchors.verticalCenter: parent.verticalCenter

                        SvgIcon {
                            anchors.centerIn: parent
                            name: "bluetooth"
                            size: 22
                            color: BluetoothData.powered ? Theme.base : Theme.overlay0
                        }
                    }

                    Column {
                        width: parent.width - 120
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: "Bluetooth"
                            color: Theme.text
                            font.pixelSize: 14
                            font.bold: true
                            font.family: Config.moduleFontFamily
                        }

                        Text {
                            text: BluetoothData.connectedDevice || (BluetoothData.powered ? "On" : "Off")
                            color: Theme.subtext0
                            font.pixelSize: 11
                            font.family: Config.moduleFontFamily
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        text: ""
                        color: Theme.overlay0
                        font.pixelSize: 16
                        font.family: Config.moduleFontFamily
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -10
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                AppState.setControlCenterView("bluetooth")
                                mouse.accepted = true
                            }
                        }
                    }
                }

                MouseArea {
                    id: btMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            AppState.setControlCenterView("bluetooth")
                        } else {
                            BluetoothData.togglePower()
                        }
                    }
                    z: -1
                }
            }


            // Wifi quick tile
            Rectangle {
                width: parent.width
                height: 70
                color: wifiMouseArea.containsMouse ? Theme.surface1 : Theme.surface0
                radius: Config.moduleRadius

                Row {
                    anchors {
                        fill: parent
                        margins: 15
                    }
                    spacing: 15

                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: WifiData.enabled ? Theme.blue : Theme.surface2
                        anchors.verticalCenter: parent.verticalCenter

                        SvgIcon {
                            anchors.centerIn: parent
                            name: WifiData.enabled ? "wifi" : "wifi-off"
                            size: 22
                            color: WifiData.enabled ? Theme.base : Theme.overlay0
                        }
                    }

                    Column {
                        width: parent.width - 120
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: "Wi-Fi"
                            color: Theme.text
                            font.pixelSize: 14
                            font.bold: true
                            font.family: Config.moduleFontFamily
                        }

                        Text {
                            text: WifiData.connectedSsid || (WifiData.enabled ? "Not connected" : "Off")
                            color: Theme.subtext0
                            font.pixelSize: 11
                            font.family: Config.moduleFontFamily
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        text: ""
                        color: Theme.overlay0
                        font.pixelSize: 16
                        font.family: Config.moduleFontFamily
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -10
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                AppState.setControlCenterView("wifi")
                                mouse.accepted = true
                            }
                        }
                    }
                }

                MouseArea {
                    id: wifiMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            AppState.setControlCenterView("wifi")
                        } else {
                            WifiData.toggleWifi()
                        }
                    }
                    z: -1
                }
            }
            // Volume slider tile
            Rectangle {
                width: parent.width
                height: 100
                color: volMouseArea.containsMouse ? Theme.surface1 : Theme.surface0
                radius: Config.moduleRadius

                MouseArea {
                    id: volMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.RightButton
                    onClicked: AppState.setControlCenterView("audio")
                    z: -1
                }

                Column {
                    anchors {
                        fill: parent
                        margins: 15
                    }
                    spacing: 10

                    Row {
                        width: parent.width
                        height: 30
                        spacing: 10

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: AudioData.outputMuted ? Theme.surface2 : Theme.mauve
                            anchors.verticalCenter: parent.verticalCenter

                            SvgIcon {
                                anchors.centerIn: parent
                                name: AudioData.outputMuted ? "volume-muted" : "volume"
                                size: 18
                                color: AudioData.outputMuted ? Theme.overlay0 : Theme.base
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: AudioData.toggleOutputMute()
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Sound"
                            color: Theme.text
                            font.pixelSize: 14
                            font.bold: true
                            font.family: Config.moduleFontFamily
                        }

                        Item { width: parent.width - 220 }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: volumeSlider.value.toFixed(0) + "%"
                            color: Theme.subtext0
                            font.pixelSize: 12
                            font.family: Config.moduleFontFamily
                        }

                        Text {
                            text: ""
                            color: Theme.overlay0
                            font.pixelSize: 16
                            font.family: Config.moduleFontFamily
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -10
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: AppState.setControlCenterView("audio")
                            }
                        }
                    }

                    Slider {
                        id: volumeSlider
                        width: parent.width
                        from: 0
                        to: 100
                        value: AudioData.outputVolume
                        stepSize: 1

                        onPressedChanged: {
                            if (!pressed) {
                                AudioData.setOutputVolume(value)
                            }
                        }

                        background: Rectangle {
                            x: parent.leftPadding
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 6
                            width: parent.availableWidth
                            height: implicitHeight
                            radius: 3
                            color: Theme.surface2

                            Rectangle {
                                width: parent.parent.visualPosition * parent.width
                                height: parent.height
                                color: Theme.mauve
                                radius: 3
                            }
                        }

                        handle: Rectangle {
                            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 10
                            color: Theme.mauve
                        }
                    }
                }
            }

            // Microphone slider tile
            Rectangle {
                width: parent.width
                height: 100
                color: micMouseArea.containsMouse ? Theme.surface1 : Theme.surface0
                radius: Config.moduleRadius

                MouseArea {
                    id: micMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.RightButton
                    onClicked: AppState.setControlCenterView("audio")
                    z: -1
                }

                Column {
                    anchors {
                        fill: parent
                        margins: 15
                    }
                    spacing: 10

                    Row {
                        width: parent.width
                        height: 30
                        spacing: 10

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: AudioData.inputMuted ? Theme.surface2 : Theme.mauve
                            anchors.verticalCenter: parent.verticalCenter

                            SvgIcon {
                                anchors.centerIn: parent
                                name: AudioData.inputMuted ? "microphone-muted" : "microphone"
                                size: 18
                                color: AudioData.inputMuted ? Theme.overlay0 : Theme.base
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: AudioData.toggleInputMute()
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Microphone"
                            color: Theme.text
                            font.pixelSize: 14
                            font.bold: true
                            font.family: Config.moduleFontFamily
                        }

                        Item { width: parent.width - 220 }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: micSlider.value.toFixed(0) + "%"
                            color: Theme.subtext0
                            font.pixelSize: 12
                            font.family: Config.moduleFontFamily
                        }
                    }

                    Slider {
                        id: micSlider
                        width: parent.width
                        from: 0
                        to: 100
                        value: AudioData.inputVolume
                        stepSize: 1

                        onPressedChanged: {
                            if (!pressed) {
                                AudioData.setInputVolume(value)
                            }
                        }

                        background: Rectangle {
                            x: parent.leftPadding
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 6
                            width: parent.availableWidth
                            height: implicitHeight
                            radius: 3
                            color: Theme.surface2

                            Rectangle {
                                width: parent.parent.visualPosition * parent.width
                                height: parent.height
                                color: Theme.mauve
                                radius: 3
                            }
                        }

                        handle: Rectangle {
                            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 10
                            color: Theme.mauve
                        }
                    }
                }
            }
        }

        // Bluetooth detail view
        Flickable {
            anchors.fill: parent
            anchors.margins: 20
            contentHeight: bluetoothDetailColumn.implicitHeight
            clip: true
            visible: AppState.controlCenterView === "bluetooth"

            Column {
                id: bluetoothDetailColumn
                width: parent.width
                spacing: 15

                Row {
                    width: parent.width
                    height: 30
                    spacing: 10

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 15
                        color: backBtMouseArea.containsMouse ? Theme.surface1 : Theme.surface0
                        anchors.verticalCenter: parent.verticalCenter

                        SvgIcon {
                            anchors.centerIn: parent
                            name: "arrow-left"
                            size: 16
                            color: Theme.text
                        }

                        MouseArea {
                            id: backBtMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AppState.setControlCenterView("main")
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Bluetooth"
                        color: Theme.text
                        font.pixelSize: 16
                        font.bold: true
                        font.family: Config.moduleFontFamily
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.surface0
                }

                Repeater {
                    model: BluetoothData.devices

                    Rectangle {
                        width: parent.width
                        height: 50
                        color: deviceMouseArea.containsMouse ? Theme.surface1 : Theme.surface0
                        radius: Config.moduleRadius

                        Row {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 15
                            }
                            spacing: 15

                            SvgIcon {
                                name: "bluetooth"
                                size: 20
                                color: modelData.connected ? Theme.green : Theme.overlay0
                            }

                            Column {
                                width: parent.width - 50
                                spacing: 2

                                Text {
                                    text: modelData.name
                                    color: Theme.text
                                    font.pixelSize: 14
                                    font.family: Config.moduleFontFamily
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: modelData.connected ? "Connected" : "Not Connected"
                                    color: modelData.connected ? Theme.green : Theme.overlay0
                                    font.pixelSize: 11
                                    font.family: Config.moduleFontFamily
                                }
                            }
                        }

                        MouseArea {
                            id: deviceMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.connected) {
                                    BluetoothData.disconnectDevice(modelData.address)
                                } else {
                                    BluetoothData.connectDevice(modelData.address)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Audio detail view
        Flickable {
            anchors.fill: parent
            anchors.margins: 20
            contentHeight: audioDetailColumn.implicitHeight
            clip: true
            visible: AppState.controlCenterView === "audio"

            Column {
                id: audioDetailColumn
                width: parent.width
                spacing: 15

                Row {
                    width: parent.width
                    height: 30
                    spacing: 10

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 15
                        color: backAudioMouseArea.containsMouse ? Theme.surface1 : Theme.surface0
                        anchors.verticalCenter: parent.verticalCenter

                        SvgIcon {
                            anchors.centerIn: parent
                            name: "arrow-left"
                            size: 16
                            color: Theme.text
                        }

                        MouseArea {
                            id: backAudioMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AppState.setControlCenterView("main")
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Audio Devices"
                        color: Theme.text
                        font.pixelSize: 16
                        font.bold: true
                        font.family: Config.moduleFontFamily
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.surface0
                }

                Text {
                    text: "Output"
                    color: Theme.text
                    font.pixelSize: 12
                    font.bold: true
                    font.family: Config.moduleFontFamily
                }

                Repeater {
                    model: AudioData.sinks

                    Rectangle {
                        width: parent.width
                        height: 50
                        color: AudioData.defaultSink === modelData.name ? Theme.surface1 : Theme.surface0
                        radius: Config.moduleRadius

                        Row {
                            anchors.centerIn: parent
                            width: parent.width - 30
                            spacing: 15

                            SvgIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: modelData.muted ? "volume-muted" : "volume"
                                size: 18
                                color: modelData.muted ? Theme.overlay0 : Theme.mauve
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 100
                                text: modelData.description
                                color: AudioData.defaultSink === modelData.name ? Theme.green : Theme.text
                                font.pixelSize: 13
                                font.family: Config.moduleFontFamily
                                elide: Text.ElideRight
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.volume + "%"
                                color: Theme.subtext0
                                font.pixelSize: 12
                                font.family: Config.moduleFontFamily
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AudioData.setDefaultSink(modelData.name)
                        }
                    }
                }

                Text {
                    text: "Input"
                    color: Theme.text
                    font.pixelSize: 12
                    font.bold: true
                    font.family: Config.moduleFontFamily
                }

                Repeater {
                    model: AudioData.sources

                    Rectangle {
                        width: parent.width
                        height: 50
                        color: AudioData.defaultSource === modelData.name ? Theme.surface1 : Theme.surface0
                        radius: Config.moduleRadius

                        Row {
                            anchors.centerIn: parent
                            width: parent.width - 30
                            spacing: 15

                            SvgIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: modelData.muted ? "microphone-muted" : "microphone"
                                size: 18
                                color: modelData.muted ? Theme.overlay0 : Theme.mauve
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 100
                                text: modelData.description
                                color: AudioData.defaultSource === modelData.name ? Theme.green : Theme.text
                                font.pixelSize: 13
                                font.family: Config.moduleFontFamily
                                elide: Text.ElideRight
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.volume + "%"
                                color: Theme.subtext0
                                font.pixelSize: 12
                                font.family: Config.moduleFontFamily
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AudioData.setDefaultSource(modelData.name)
                        }
                    }
                }
            }
        }

        // Wifi detail view
        Flickable {
            anchors.fill: parent
            anchors.margins: 20
            contentHeight: wifiDetailColumn.implicitHeight
            clip: true
            visible: AppState.controlCenterView === "wifi"

            Column {
                id: wifiDetailColumn
                width: parent.width
                spacing: 15

                Row {
                    width: parent.width
                    height: 30
                    spacing: 10

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 15
                        color: backWifiMouseArea.containsMouse ? Theme.surface1 : Theme.surface0
                        anchors.verticalCenter: parent.verticalCenter

                        SvgIcon {
                            anchors.centerIn: parent
                            name: "arrow-left"
                            size: 16
                            color: Theme.text
                        }

                        MouseArea {
                            id: backWifiMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AppState.setControlCenterView("main")
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Wi-Fi"
                        color: Theme.text
                        font.pixelSize: 16
                        font.bold: true
                        font.family: Config.moduleFontFamily
                    }

                    Item { width: parent.width - 120 }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.surface0
                }

                Repeater {
                    model: WifiData.networks

                    Rectangle {
                        width: parent.width
                        height: 50
                        color: modelData.active ? Theme.surface1 : (wifiNetMouseArea.containsMouse ? Theme.surface1 : Theme.surface0)
                        radius: Config.moduleRadius

                        Row {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 15
                            }
                            spacing: 12

                            SvgIcon {
                                name: "wifi"
                                size: 18
                                color: modelData.active ? Theme.blue : Theme.overlay0
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                width: parent.width - 80
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: modelData.ssid
                                    color: modelData.active ? Theme.blue : Theme.text
                                    font.pixelSize: 13
                                    font.bold: modelData.active
                                    font.family: Config.moduleFontFamily
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: modelData.active ? "Connected" : (modelData.security ? modelData.security : "Open")
                                    color: modelData.active ? Theme.blue : Theme.overlay0
                                    font.pixelSize: 11
                                    font.family: Config.moduleFontFamily
                                }
                            }

                            Text {
                                text: modelData.signal + "%"
                                color: Theme.subtext0
                                font.pixelSize: 11
                                font.family: Config.moduleFontFamily
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: wifiNetMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.active) {
                                    WifiData.disconnectNetwork()
                                } else {
                                    WifiData.connectNetwork(modelData.ssid)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
