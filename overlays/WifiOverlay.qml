import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "root:/"
import "root:/singletons"
import "root:/components"

PanelWindow {
    id: wifiOverlay

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

    // ── connection details ───────────────────────────────────────────────────
    property string connIp:      "—"
    property string connGateway: "—"
    property string connPing:    "—"
    property string connDns:     "—"

    function refreshDetails() {
        detailProc.running = false
        detailProc.running = true
        pingProc.running = false
        pingProc.running = true
    }

    Process {
        id: detailProc
        command: ["sh", "-c", [
            // wifi interface IP + gateway
            "IFACE=$(nmcli -t -f DEVICE,TYPE device | grep ':wifi$' | cut -d: -f1 | head -1)",
            "IP=$(ip addr show $IFACE 2>/dev/null | awk '/inet /{print $2}' | head -1)",
            "GW=$(ip route show dev $IFACE default 2>/dev/null | awk '{print $3}' | head -1)",
            "DNS=$(nmcli dev show $IFACE 2>/dev/null | awk '/IP4.DNS/{print $2}' | head -1)",
            "echo \"IP:${IP:-—}\"",
            "echo \"GW:${GW:-—}\"",
            "echo \"DNS:${DNS:-—}\""
        ].join("; ")]
        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("IP:"))  wifiOverlay.connIp      = line.substring(3).trim()
                else if (line.startsWith("GW:"))  wifiOverlay.connGateway = line.substring(3).trim()
                else if (line.startsWith("DNS:")) wifiOverlay.connDns     = line.substring(4).trim()
            }
        }
    }

    Process {
        id: pingProc
        command: ["sh", "-c", "ping -c 1 -W 2 8.8.8.8 2>/dev/null | awk -F'time=' '/time=/{print $2}' | awk '{print $1 \" ms\"}'"]
        stdout: SplitParser {
            onRead: line => {
                var v = line.trim()
                wifiOverlay.connPing = v !== "" ? v : "timeout"
            }
        }
        onRunningChanged: { if (running) wifiOverlay.connPing = "…" }
    }

    onVisibleChanged: {
        if (visible) {
            WifiData.refresh()
            refreshDetails()
        }
    }

    // ── layout ───────────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: AppState.toggleWifiOverlay()
        z: -1
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 12
            rightMargin: Math.min(AppState.screenWidth - 350 - 10, Math.max(10, AppState.screenWidth - AppState.lastClickX - 350 / 2))
        }
        width: 350
        height: Math.min(contentColumn.implicitHeight + 40, wifiOverlay.height - Config.barHeight - 50)
        color: Theme.mantle
        radius: Config.overlayRadius
        border.color: Theme.surface0
        border.width: 1

        MouseArea { anchors.fill: parent; onClicked: {} }

        Flickable {
            anchors.fill: parent
            anchors.margins: 20
            contentHeight: contentColumn.implicitHeight
            clip: true

            Column {
                id: contentColumn
                width: parent.width
                spacing: 15

                // ── Header ────────────────────────────────────────────────
                Item {
                    width: parent.width
                    height: 28

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        SvgIcon {
                            name: WifiData.enabled ? "wifi" : "wifi-off"
                            size: 20
                            color: WifiData.enabled ? Theme.blue : Theme.overlay0
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Wi-Fi"
                            color: Theme.text
                            font.pixelSize: 16
                            font.bold: true
                            font.family: Config.moduleFontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // Toggle switch
                        Rectangle {
                            width: 52
                            height: 28
                            color: Theme.surface0
                            radius: 14
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: 22
                                height: 22
                                radius: 11
                                color: WifiData.enabled ? Theme.blue : Theme.overlay0
                                x: WifiData.enabled ? parent.width - width - 3 : 3
                                y: 3
                                Behavior on x { NumberAnimation { duration: 200 } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: WifiData.toggleWifi()
                            }
                        }

                        // Refresh button
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: refreshMouse.containsMouse ? Theme.surface1 : Theme.surface0
                            anchors.verticalCenter: parent.verticalCenter

                            SvgIcon {
                                anchors.centerIn: parent
                                name: "refresh"
                                size: 14
                                color: Theme.subtext0
                            }

                            MouseArea {
                                id: refreshMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    WifiData.refresh()
                                    wifiOverlay.refreshDetails()
                                }
                            }
                        }
                    }
                }

                // ── Connected network details ─────────────────────────────
                Rectangle {
                    width: parent.width
                    height: detailsCol.implicitHeight + 24
                    color: Theme.surface0
                    radius: Config.moduleRadius
                    visible: WifiData.connectedSsid !== ""

                    Column {
                        id: detailsCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 14
                        }
                        spacing: 8

                        // SSID + signal row
                        Row {
                            width: parent.width
                            spacing: 10

                            SvgIcon {
                                name: "wifi"
                                size: 16
                                color: Theme.green
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: WifiData.connectedSsid
                                color: Theme.green
                                font.pixelSize: 13
                                font.bold: true
                                font.family: Config.moduleFontFamily
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                width: parent.width - 60
                            }

                            Text {
                                text: WifiData.connectedSignal + "%"
                                color: Theme.subtext0
                                font.pixelSize: 11
                                font.family: Config.moduleFontFamily
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Divider
                        Rectangle { width: parent.width; height: 1; color: Theme.surface1 }

                        // Stats grid
                        Grid {
                            width: parent.width
                            columns: 2
                            columnSpacing: 12
                            rowSpacing: 6

                            DetailLabel { text: "IP" }
                            DetailValue { text: wifiOverlay.connIp }

                            DetailLabel { text: "Gateway" }
                            DetailValue { text: wifiOverlay.connGateway }

                            DetailLabel { text: "DNS" }
                            DetailValue { text: wifiOverlay.connDns }

                            DetailLabel { text: "Ping" }
                            DetailValue {
                                text: wifiOverlay.connPing
                                color: {
                                    var ms = parseFloat(wifiOverlay.connPing)
                                    if (isNaN(ms)) return Theme.overlay0
                                    if (ms < 30)   return Theme.green
                                    if (ms < 80)   return Theme.yellow
                                    return Theme.peach
                                }
                            }
                        }
                    }
                }

                // ── Divider ───────────────────────────────────────────────
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.surface0
                }

                // ── Network list ──────────────────────────────────────────
                Column {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: WifiData.networks

                        Rectangle {
                            width: parent.width
                            height: 50
                            color: modelData.active
                                ? Config.alpha(Theme.blue, 0.12)
                                : (netMouse.containsMouse ? Theme.surface1 : Theme.surface0)
                            radius: Config.moduleRadius
                            border.color: modelData.active ? Theme.blue : "transparent"
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    margins: 14
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
                                        text: modelData.active ? "Connected" : (modelData.security !== "" ? modelData.security : "Open")
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
                                id: netMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.active) WifiData.disconnectNetwork()
                                    else WifiData.connectNetwork(modelData.ssid)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── inline components ────────────────────────────────────────────────────
    component DetailLabel: Text {
        color: Theme.overlay1
        font.pixelSize: 11
        font.family: Config.moduleFontFamily
    }

    component DetailValue: Text {
        color: Theme.subtext1
        font.pixelSize: 11
        font.family: Config.moduleFontFamily
    }
}
