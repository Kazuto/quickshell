import QtQuick
import Quickshell.Io
import "root:/"
import "root:/singletons"
import "root:/components"

// F4: the VPN tile
PanelFrame {
    id: panel

    readonly property bool connected: VpnData.connected
    property string tunnelIp: "—"
    property string server: "—"
    property string protocol: "—"
    property string iface: "—"
    property string downRate: "—"
    property string upRate: "—"
    property real lastRx: -1
    property real lastTx: -1
    property real lastSampleAt: 0
    property string ping: "—"

    backTo: "control"
    spacing: 12

    function sampleTraffic(rx, tx) {
        var now = Date.now()
        if (lastRx >= 0 && rx >= lastRx && tx >= lastTx) {
            var seconds = (now - lastSampleAt) / 1000
            downRate = SystemStatsData.formatRate((rx - lastRx) / seconds)
            upRate = SystemStatsData.formatRate((tx - lastTx) / seconds)
        }
        lastRx = rx
        lastTx = tx
        lastSampleAt = now
    }

    function refreshDetails() {
        if (!connected) return
        if (!infoProcess.running) infoProcess.running = true
        if (!pingProcess.running) pingProcess.running = true
    }

    Component.onCompleted: {
        VpnData.refresh()
        refreshDetails()
    }

    onConnectedChanged: {
        if (connected) {
            refreshDetails()
        } else {
            tunnelIp = server = protocol = iface = downRate = upRate = ping = "—"
            lastRx = lastTx = -1
        }
    }

    Process {
        id: infoProcess
        command: ["sh", "-c",
            "export LC_ALL=C; NAME=$1;" +
            "STATE=$(nmcli -g GENERAL.STATE connection show \"$NAME\" 2>/dev/null);" +
            "if [ \"$STATE\" = \"activated\" ]; then" +
            "  IFACE=$(ip -o link show type tun 2>/dev/null | awk -F\": \" \"{print \\$2}\" | head -1);" +
            "  [ -z \"$IFACE\" ] && IFACE=$(ip -o link show | grep tun | awk -F\": \" \"{print \\$2}\" | head -1);" +
            "  echo \"IFACE:$IFACE\";" +
            "  IP=$(ip addr show \"$IFACE\" 2>/dev/null | awk \"/inet /{print \\$2}\" | head -1);" +
            "  echo \"IP:$IP\";" +
            "  SERVER=$(nmcli connection show \"$NAME\" 2>/dev/null | grep vpn.data | grep -o \"remote = [^,]*\" | sed \"s/remote = //\");" +
            "  echo \"SERVER:$SERVER\";" +
            "  PROTO=$(nmcli -g vpn.service-type connection show \"$NAME\" 2>/dev/null); PROTO=${PROTO##*.};" +
            "  echo \"PROTO:$PROTO\";" +
            "  STATS=$(grep \"$IFACE\" /proc/net/dev | awk \"{print \\$2, \\$10}\");" +
            "  echo \"STATS:$STATS\";" +
            "fi", "vpn-info", VpnData.connectionName
        ]
        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("IFACE:")) { panel.iface = line.substring(6).trim(); return }
                if (line.startsWith("IP:")) { panel.tunnelIp = line.substring(3).trim(); return }
                if (line.startsWith("SERVER:")) { panel.server = line.substring(7).trim(); return }
                if (line.startsWith("PROTO:")) { panel.protocol = line.substring(6).trim(); return }
                if (line.startsWith("STATS:")) {
                    var bytes = line.substring(6).trim().split(/\s+/)
                    panel.sampleTraffic(parseFloat(bytes[0]), parseFloat(bytes[1]))
                }
            }
        }
    }

    Process {
        id: pingProcess
        command: ["sh", "-c", "ping -c 1 -W 2 8.8.8.8 2>/dev/null | awk -F'time=' '/time=/{print $2}' | awk '{print $1 \" ms\"}'"]
        stdout: StdioCollector {
            onStreamFinished: panel.ping = this.text.trim() || "timeout"
        }
    }

    // Traffic moves while the panel is open. The first rate needs two samples,
    // so the second one comes quickly.
    Timer {
        interval: panel.downRate === "—" ? 1000 : 3000
        running: panel.connected
        repeat: true
        onTriggered: panel.refreshDetails()
    }

    headerLeft: [
        IslandLabel {
            text: "VPN"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        IslandSwitch {
            checked: panel.connected
            active: !VpnData.busy && !VpnData.checking
            anchors.verticalCenter: parent.verticalCenter
            onToggled: VpnData.toggle()
        }
    ]

    Row {
        spacing: 8

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: panel.connected ? Theme.accent : Theme.textFaint
            anchors.verticalCenter: parent.verticalCenter
        }

        IslandLabel {
            text: VpnData.busy ? "Working…" : panel.connected ? "Connected" : "Not connected"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        }

        IslandLabel {
            text: VpnData.connectionName
            color: Theme.textDim
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    DetailCard {
        visible: panel.connected
        width: parent.width
        labelWidth: 108
        rows: [
            { label: "Server", value: panel.server },
            { label: "Protocol", value: panel.protocol },
            { label: "Interface", value: panel.iface },
            { label: "Tunnel IP", value: panel.tunnelIp },
            { label: "Ping", value: panel.ping, color: parseFloat(panel.ping) >= 80 ? Theme.warn : Theme.text }
        ]
    }

    Row {
        visible: panel.connected
        width: parent.width
        spacing: 8

        MiniStat {
            width: (parent.width - parent.spacing) / 2
            label: "Down"
            value: panel.downRate
            valueKind: "title"
            valueColor: Theme.accentSky
        }

        MiniStat {
            width: (parent.width - parent.spacing) / 2
            label: "Up"
            value: panel.upRate
            valueKind: "title"
            valueColor: Theme.accentSky
        }
    }

    IslandLabel {
        visible: VpnData.error !== ""
        width: parent.width
        maximumLineCount: 3
        wrapMode: Text.Wrap
        text: VpnData.error
        kind: "meta"
        color: Theme.warn
    }
}
