import QtQuick
import Quickshell.Io
import "root:/"
import "root:/singletons"
import "root:/components"

// F1: the Network tile
PanelFrame {
    id: panel

    property string ip: "—"
    property string gateway: "—"
    property string dns: "—"
    property string ping: "—"
    property string promptSsid: ""
    property bool showAll: false

    readonly property bool onWifi: WifiData.connectedSsid !== ""
    readonly property bool online: onWifi || WifiData.wiredConnected
    readonly property var available: WifiData.networks.filter(n => !n.active)
    readonly property var shown: showAll ? available : available.slice(0, 4)

    backTo: "control"
    spacing: 12

    function refresh() {
        WifiData.refresh()
        detailProcess.running = false
        detailProcess.running = true
        pingProcess.running = false
        pingProcess.running = true
    }

    Component.onCompleted: refresh()

    function closePrompt() {
        promptSsid = ""
        panel.forceActiveFocus()
    }

    function choose(network) {
        if (network.security !== "" && WifiData.savedSsids.indexOf(network.ssid) < 0) {
            promptSsid = promptSsid === network.ssid ? "" : network.ssid
        } else {
            WifiData.connectNetwork(network.ssid)
            AppState.closePanel()
        }
    }

    function submit(password) {
        if (promptSsid === "" || password === "") return
        WifiData.connectNetworkWithPassword(promptSsid, password)
        AppState.closePanel()
    }

    // Details of whichever link is up, wired or wireless
    Process {
        id: detailProcess
        command: ["sh", "-c", [
            "IFACE=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '($2==\"ethernet\"||$2==\"wifi\")&&$3==\"connected\"{print $1;exit}')",
            "IP=$(ip addr show $IFACE 2>/dev/null | awk '/inet /{print $2}' | head -1)",
            "GW=$(ip route show dev $IFACE default 2>/dev/null | awk '{print $3}' | head -1)",
            "DNS=$(nmcli dev show $IFACE 2>/dev/null | awk '/IP4.DNS/{print $2}' | head -1)",
            "echo \"IP:${IP:-—}\"",
            "echo \"GW:${GW:-—}\"",
            "echo \"DNS:${DNS:-—}\""
        ].join("; ")]
        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("IP:")) { panel.ip = line.substring(3).trim(); return }
                if (line.startsWith("GW:")) { panel.gateway = line.substring(3).trim(); return }
                if (line.startsWith("DNS:")) { panel.dns = line.substring(4).trim() }
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

    headerLeft: [
        IslandLabel {
            text: "Wi-Fi"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        IslandButton {
            implicitHeight: 28
            iconName: "refresh"
            iconSize: 12
            anchors.verticalCenter: parent.verticalCenter
            onClicked: panel.refresh()
        },
        IslandSwitch {
            checked: WifiData.enabled
            anchors.verticalCenter: parent.verticalCenter
            onToggled: WifiData.toggleWifi()
        }
    ]

    DetailCard {
        visible: panel.online
        width: parent.width
        rows: [
            { label: "IP", value: panel.ip },
            { label: "Gateway", value: panel.gateway },
            { label: "DNS", value: panel.dns },
            { label: "Ping", value: panel.ping, color: parseFloat(panel.ping) >= 80 ? Theme.warn : Theme.text }
        ]

        Item {
            width: parent.width
            height: 24

            HoverHandler { id: linkHover }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                SvgIcon {
                    name: panel.onWifi ? "wifi" : "network"
                    size: 14
                    color: Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                }

                IslandLabel {
                    text: panel.onWifi ? WifiData.connectedSsid : "Ethernet"
                    kind: "island"
                    anchors.verticalCenter: parent.verticalCenter
                }

                IslandLabel {
                    text: "connected"
                    kind: "meta"
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            IslandLabel {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: panel.onWifi && !linkHover.hovered
                text: WifiData.connectedSignal + "%"
                kind: "meta"
            }

            IslandButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: panel.onWifi && linkHover.hovered
                implicitHeight: 24
                variant: "selected"
                label: "Disconnect"
                onClicked: WifiData.disconnectNetwork()
            }
        }
    }

    Column {
        visible: WifiData.enabled && panel.available.length > 0
        width: parent.width
        spacing: 4

        IslandLabel { height: 20; text: "Available"; kind: "meta" }

        Flickable {
            width: parent.width
            height: Math.min(networks.implicitHeight, 300)
            contentHeight: networks.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Column {
                id: networks
                width: parent.width

                Repeater {
                    model: panel.shown

                    delegate: Column {
                        id: entry

                        required property var modelData

                        width: networks.width

                        Rectangle {
                            width: parent.width
                            height: 48
                            radius: Config.controlRadius
                            color: networkMouse.containsMouse ? Theme.surfaceLow : "transparent"

                            SvgIcon {
                                id: signalIcon
                                x: 12
                                anchors.verticalCenter: parent.verticalCenter
                                name: entry.modelData.signal >= 50 ? "wifi" : "wifi-low"
                                size: 14
                                color: Theme.text
                            }

                            Row {
                                anchors.left: signalIcon.right
                                anchors.leftMargin: 10
                                anchors.right: strength.left
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                IslandLabel {
                                    width: Math.min(implicitWidth, parent.width - 60)
                                    text: entry.modelData.ssid
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                IslandLabel {
                                    text: WifiData.securityLabel(entry.modelData.security)
                                    kind: "meta"
                                    font.pixelSize: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            IslandLabel {
                                id: strength
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: entry.modelData.signal + "%"
                                kind: "meta"
                            }

                            MouseArea {
                                id: networkMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: panel.choose(entry.modelData)
                            }
                        }

                        Rectangle {
                            visible: panel.promptSsid === entry.modelData.ssid
                            width: parent.width
                            height: visible ? 44 : 0
                            radius: Config.controlRadius
                            color: Theme.surfaceLow
                            border.width: 1
                            border.color: password.activeFocus ? Theme.accent : Theme.stroke

                            onVisibleChanged: {
                                if (visible) {
                                    password.text = ""
                                    Qt.callLater(() => password.forceActiveFocus())
                                }
                            }

                            TextInput {
                                id: password
                                x: 14
                                width: parent.width - 14 - joinButton.width - 20
                                height: parent.height
                                verticalAlignment: TextInput.AlignVCenter
                                color: Theme.text
                                selectionColor: Theme.accent
                                font.pixelSize: 12
                                font.family: Config.moduleFontFamily
                                clip: true
                                echoMode: TextInput.Password
                                onAccepted: panel.submit(text)
                                Keys.onEscapePressed: panel.closePrompt()
                            }

                            IslandLabel {
                                x: 14
                                visible: password.text === ""
                                height: parent.height
                                text: "Password"
                                color: Theme.textDim
                            }

                            IslandButton {
                                id: joinButton
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                implicitHeight: 32
                                label: "Join"
                                variant: "accent"
                                active: password.text !== ""
                                onClicked: panel.submit(password.text)
                            }
                        }
                    }
                }
            }
        }

        IslandLabel {
            visible: panel.available.length > 4
            width: parent.width
            height: 28
            horizontalAlignment: Text.AlignHCenter
            text: panel.showAll ? "Show less" : "Show " + (panel.available.length - 4) + " more"
            kind: "meta"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: panel.showAll = !panel.showAll
            }
        }
    }

    IslandLabel {
        visible: !WifiData.enabled || panel.available.length === 0
        width: parent.width
        height: 40
        horizontalAlignment: Text.AlignHCenter
        text: WifiData.enabled ? "No networks found" : "Wi-Fi is off"
        kind: "meta"
    }
}
