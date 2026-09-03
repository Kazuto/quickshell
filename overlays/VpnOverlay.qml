import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "root:/"
import "root:/singletons"
import "root:/components"

PanelWindow {
    id: vpnOverlay

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

    // ── data ─────────────────────────────────────────────────────────────────
    property bool    connected:   false
    property string  tunnelIp:    "—"
    property string  server:      "—"
    property string  protocol:    "—"
    property string  iface:       "—"
    property string  rxBytes:     "—"
    property string  txBytes:     "—"
    property string  ping:        "—"
    property string  connName:    "my-vpn"

    function formatBytes(b) {
        var n = parseInt(b) || 0
        if (n >= 1073741824) return (n / 1073741824).toFixed(2) + " GB"
        if (n >= 1048576)    return (n / 1048576).toFixed(1) + " MB"
        if (n >= 1024)       return (n / 1024).toFixed(0) + " KB"
        return n + " B"
    }

    function refresh() {
        infoProc.running = false
        infoProc.running = true
        pingProc.running = false
        pingProc.running = true
    }

    Process {
        id: infoProc
        command: ["sh", "-c",
            "NAME=my-vpn;" +
            "STATE=$(nmcli -t -f NAME,STATE connection show --active 2>/dev/null | grep \"^$NAME:\" | cut -d: -f2);" +
            "if [ \"$STATE\" = \"activated\" ]; then" +
            "  echo CONNECTED:yes;" +
            "  IFACE=$(ip -o link show type tun 2>/dev/null | awk -F\": \" \"{print \\$2}\" | head -1);" +
            "  [ -z \"$IFACE\" ] && IFACE=$(ip -o link show | grep tun | awk -F\": \" \"{print \\$2}\" | head -1);" +
            "  echo \"IFACE:$IFACE\";" +
            "  IP=$(ip addr show \"$IFACE\" 2>/dev/null | awk \"/inet /{print \\$2}\" | head -1);" +
            "  echo \"IP:$IP\";" +
            "  SERVER=$(nmcli connection show \"$NAME\" 2>/dev/null | grep vpn.data | grep -o \"remote = [^,]*\" | sed \"s/remote = //\");" +
            "  echo \"SERVER:$SERVER\";" +
            "  PROTO=$(nmcli connection show \"$NAME\" 2>/dev/null | grep VPN.TYPE | awk \"{print \\$2}\");" +
            "  echo \"PROTO:$PROTO\";" +
            "  STATS=$(grep \"$IFACE\" /proc/net/dev | awk \"{print \\$2, \\$10}\");" +
            "  echo \"RX:$(echo $STATS | awk \"{print \\$1}\")\";" +
            "  echo \"TX:$(echo $STATS | awk \"{print \\$2}\")\";" +
            "else echo CONNECTED:no; fi"
        ]
        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("CONNECTED:")) { vpnOverlay.connected = line.substring(10).trim() === "yes"; return }
                if (line.startsWith("IFACE:"))     { vpnOverlay.iface     = line.substring(6).trim(); return }
                if (line.startsWith("IP:"))        { vpnOverlay.tunnelIp  = line.substring(3).trim(); return }
                if (line.startsWith("SERVER:"))    { vpnOverlay.server    = line.substring(7).trim(); return }
                if (line.startsWith("PROTO:"))     { vpnOverlay.protocol  = line.substring(6).trim(); return }
                if (line.startsWith("RX:"))        { vpnOverlay.rxBytes   = vpnOverlay.formatBytes(line.substring(3).trim()); return }
                if (line.startsWith("TX:"))        { vpnOverlay.txBytes   = vpnOverlay.formatBytes(line.substring(3).trim()) }
            }
        }
    }

    Process {
        id: pingProc
        command: ["sh", "-c", "ping -c 1 -W 2 8.8.8.8 2>/dev/null | awk -F'time=' '/time=/{print $2}' | awk '{print $1 \" ms\"}'"]
        stdout: SplitParser {
            onRead: line => { vpnOverlay.ping = line.trim() !== "" ? line.trim() : "timeout" }
        }
        onRunningChanged: { if (running) vpnOverlay.ping = "…" }
    }

    // Refresh traffic stats every 3s while open
    Timer {
        interval: 3000
        running: vpnOverlay.visible && vpnOverlay.connected
        repeat: true
        onTriggered: { infoProc.running = false; infoProc.running = true }
    }

    onVisibleChanged: { if (visible) refresh() }

    // ── UI ───────────────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: AppState.toggleVpnOverlay()
        z: -1
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 12
            rightMargin: Math.min(AppState.screenWidth - 320 - 10, Math.max(10, AppState.screenWidth - AppState.lastClickX - 320 / 2))
        }
        width: 320
        height: content.implicitHeight + 40
        color: Theme.mantle
        radius: Config.overlayRadius
        border.color: Theme.surface0
        border.width: 1

        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
            id: content
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 20
            }
            spacing: 16

            // ── Header ────────────────────────────────────────────────────
            Item {
                width: parent.width
                height: 28

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    SvgIcon {
                        name: "vpn"
                        size: 18
                        color: vpnOverlay.connected ? Theme.green : Theme.overlay0
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "VPN"
                        color: Theme.text
                        font.pixelSize: 16
                        font.bold: true
                        font.family: Config.moduleFontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Connect / Disconnect button
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: toggleMouse.containsMouse ? labelText.implicitWidth + 20 : 28
                    height: 28
                    radius: 14
                    color: vpnOverlay.connected
                        ? Config.alpha(Theme.red, toggleMouse.containsMouse ? 0.25 : 0.15)
                        : Config.alpha(Theme.green, toggleMouse.containsMouse ? 0.25 : 0.15)
                    border.color: vpnOverlay.connected ? Theme.red : Theme.green
                    border.width: 1

                    Behavior on width { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: labelText
                        anchors.centerIn: parent
                        text: vpnOverlay.connected ? "Disconnect" : "Connect"
                        color: vpnOverlay.connected ? Theme.red : Theme.green
                        font.pixelSize: 11
                        font.family: Config.moduleFontFamily
                        visible: toggleMouse.containsMouse
                    }

                    SvgIcon {
                        anchors.centerIn: parent
                        name: vpnOverlay.connected ? "logout" : "lock"
                        size: 13
                        color: vpnOverlay.connected ? Theme.red : Theme.green
                        visible: !toggleMouse.containsMouse
                    }

                    MouseArea {
                        id: toggleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            toggleProc.running = false
                            toggleProc.running = true
                        }
                    }
                }
            }

            // ── Status badge ──────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: 36
                radius: Config.moduleRadius
                color: vpnOverlay.connected
                    ? Config.alpha(Theme.green, 0.12)
                    : Config.alpha(Theme.overlay0, 0.08)
                border.color: vpnOverlay.connected ? Config.alpha(Theme.green, 0.3) : "transparent"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: vpnOverlay.connected
                        ? "● Connected — " + vpnOverlay.connName
                        : "○ Not connected"
                    color: vpnOverlay.connected ? Theme.green : Theme.overlay0
                    font.pixelSize: 12
                    font.family: Config.moduleFontFamily
                    font.bold: vpnOverlay.connected
                }
            }

            // ── Details ───────────────────────────────────────────────────
            Column {
                width: parent.width
                spacing: 8
                visible: vpnOverlay.connected

                Rectangle {
                    width: parent.width
                    height: detailGrid.implicitHeight + 24
                    color: Theme.surface0
                    radius: Config.moduleRadius

                    Grid {
                        id: detailGrid
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 14
                        }
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 8

                        StatLabel { text: "Server" }
                        StatValue { text: vpnOverlay.server }

                        StatLabel { text: "Protocol" }
                        StatValue { text: vpnOverlay.protocol }

                        StatLabel { text: "Interface" }
                        StatValue { text: vpnOverlay.iface }

                        StatLabel { text: "Tunnel IP" }
                        StatValue { text: vpnOverlay.tunnelIp }

                        StatLabel { text: "Ping" }
                        StatValue {
                            text: vpnOverlay.ping
                            color: {
                                var ms = parseFloat(vpnOverlay.ping)
                                if (isNaN(ms))  return Theme.overlay0
                                if (ms < 30)    return Theme.green
                                if (ms < 80)    return Theme.yellow
                                return Theme.peach
                            }
                        }
                    }
                }

                // ── Traffic ───────────────────────────────────────────────
                Row {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: (parent.width - 8) / 2
                        height: 52
                        color: Theme.surface0
                        radius: Config.moduleRadius

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "DOWNLOAD"
                                color: Theme.overlay0
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 1.2
                                font.family: Config.moduleFontFamily
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: vpnOverlay.rxBytes
                                color: Theme.blue
                                font.pixelSize: 13
                                font.bold: true
                                font.family: Config.moduleFontFamily
                            }
                        }
                    }

                    Rectangle {
                        width: (parent.width - 8) / 2
                        height: 52
                        color: Theme.surface0
                        radius: Config.moduleRadius

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "UPLOAD"
                                color: Theme.overlay0
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 1.2
                                font.family: Config.moduleFontFamily
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: vpnOverlay.txBytes
                                color: Theme.mauve
                                font.pixelSize: 13
                                font.bold: true
                                font.family: Config.moduleFontFamily
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: toggleProc
        command: vpnOverlay.connected
            ? ["nmcli", "connection", "down", vpnOverlay.connName]
            : ["nmcli", "connection", "up",   vpnOverlay.connName]
        onExited: {
            Qt.callLater(() => { infoProc.running = false; infoProc.running = true })
        }
    }

    component StatLabel: Text {
        color: Theme.overlay1
        font.pixelSize: 11
        font.family: Config.moduleFontFamily
    }

    component StatValue: Text {
        color: Theme.subtext1
        font.pixelSize: 11
        font.family: Config.moduleFontFamily
    }
}
