import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

// The resting island: workspaces, clock and status glyphs. While a bubble is up
// the wings shrink to occupied workspaces and the clock alone (states 05, 06).
Item {
    id: root

    required property var screen
    property bool shrunk: false

    readonly property int cornerRadius: Config.islandHeight / 2

    implicitWidth: row.implicitWidth + 2 * 14
    implicitHeight: Config.islandHeight

    // Right-click anywhere reaches the control center, also while the wings
    // are shrunk and its glyphs aren't showing.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: AppState.togglePanel("control", root.screen.name)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        WorkspaceDots {
            screen: root.screen
            shrunk: root.shrunk
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            implicitWidth: clockRow.implicitWidth
            implicitHeight: Config.islandHeight
            anchors.verticalCenter: parent.verticalCenter

            Row {
                id: clockRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                IslandLabel {
                    text: IslandData.clockText
                    kind: "island"
                }

                IslandLabel {
                    visible: !root.shrunk
                    text: IslandData.dateText
                    color: coreMouse.containsMouse ? Theme.text : Theme.textDim
                }
            }

            MouseArea {
                id: coreMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: AppState.togglePanel("calendar", root.screen.name)
                onWheel: wheel => OsdData.showVolume(
                    AudioData.stepOutputVolume(wheel.angleDelta.y > 0 ? 5 : -5), false)
            }
        }

        Row {
            visible: !root.shrunk
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter

            Item {
                implicitWidth: glyphs.implicitWidth
                implicitHeight: Config.islandHeight

                Row {
                    id: glyphs
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    SvgIcon {
                        name: WifiData.wiredConnected && WifiData.connectedSsid === "" ? "network" : WifiData.enabled ? "wifi" : "wifi-off"
                        size: 14
                        color: wingMouse.containsMouse ? Theme.text : Theme.textDim
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    SvgIcon {
                        name: AudioData.outputMuted ? "volume-muted" : "volume"
                        size: 14
                        color: wingMouse.containsMouse ? Theme.text : Theme.textDim
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: wingMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AppState.togglePanel("control", root.screen.name)
                }
            }

            Item {
                visible: UpdateData.needsAttention
                implicitWidth: 14
                implicitHeight: Config.islandHeight

                SvgIcon {
                    anchors.centerIn: parent
                    name: "update"
                    size: 14
                    color: UpdateData.warnings.length > 0 ? Theme.warn : Theme.accent
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AppState.togglePanel("updates", root.screen.name)
                }
            }

            Item {
                implicitWidth: 14
                implicitHeight: Config.islandHeight

                SvgIcon {
                    anchors.centerIn: parent
                    name: NotificationData.paused ? "bell-slash" : "bell"
                    size: 14
                    color: NotificationData.notifications.length + GitHubData.notifications.length > 0
                        ? Theme.accent
                        : bellMouse.containsMouse ? Theme.text : Theme.textDim
                }

                MouseArea {
                    id: bellMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AppState.togglePanel("notifications", root.screen.name)
                }
            }
        }
    }
}
