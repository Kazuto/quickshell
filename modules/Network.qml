import QtQuick
import Quickshell.Io
import "root:/"
import "root:/components"

Rectangle {
    id: root
    implicitWidth: vpnText.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: vpnMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    // Replace with your actual nmcli connection profile name
    // (check with: nmcli connection show)
    property string vpnConnectionName: "my-vpn"
    property bool vpnConnected: false
    property bool vpnBusy: false

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    Row {
        id: vpnText
        anchors.centerIn: parent
        spacing: 6

        SvgIcon {
            name: "vpn"
            size: Config.moduleFontSize
            color: root.vpnConnected ? Theme.green : Theme.overlay0
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.vpnBusy ? 0.5 : 1.0
        }

        Text {
            text: "VPN"
            color: root.vpnConnected ? Theme.green : Theme.overlay0
            font.pixelSize: Config.moduleFontSize
            font.family: Config.moduleFontFamily
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.vpnBusy ? 0.5 : 1.0
        }
    }

    // Checks whether the VPN connection is currently active
    Process {
        id: statusProcess
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show", "--active"]
        property string output: ""
        stdout: SplitParser {
            onRead: line => {
                if (line.trim() === root.vpnConnectionName)
                    root.vpnConnected = true
            }
        }
        onRunningChanged: {
            if (running) root.vpnConnected = false
        }
    }

    // Brings the VPN up or down
    Process {
        id: toggleProcess
        command: root.vpnConnected
            ? ["nmcli", "connection", "down", root.vpnConnectionName]
            : ["nmcli", "connection", "up", root.vpnConnectionName]
        onExited: (exitCode, exitStatus) => {
            root.vpnBusy = false
            statusProcess.running = true
        }
    }

    function refreshVpnStatus() {
        statusProcess.running = true
    }

    Component.onCompleted: refreshVpnStatus()

    // Periodically re-check in case VPN drops/reconnects outside this widget
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refreshVpnStatus()
    }

    MouseArea {
        id: vpnMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !root.vpnBusy
        onClicked: {
            root.vpnBusy = true
            toggleProcess.running = true
        }
    }
}
