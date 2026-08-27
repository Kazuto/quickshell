import QtQuick
import Quickshell.Io
import "root:/"
import "root:/singletons"
import "root:/components"

Rectangle {
    id: root
    implicitWidth: Config.barHeight
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

    SvgIcon {
        id: vpnText
        anchors.centerIn: parent
        name: "vpn"
        size: Config.moduleFontSize
        color: root.vpnConnected ? Theme.green : Theme.overlay0
        opacity: root.vpnBusy ? 0.5 : 1.0
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
        onClicked: { AppState.lastClickX = mapToItem(null, width / 2, 0).x; AppState.toggleVpnOverlay() }
    }
}
