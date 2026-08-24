import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/singletons"
import "root:/components"

PanelWindow {
    id: githubOverlay

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

    onVisibleChanged: {
        if (visible) {
            GitHubData.refresh()
        }
    }

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: AppState.toggleGitHubOverlay()
        z: -1
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 12
            rightMargin: 20
        }
        width: 450
        height: Math.min(700, parent.height - Config.barHeight - Config.barMarginTop - 40)
        color: Config.alpha(Theme.base, 0.95)
        radius: Config.overlayRadius
        border.color: Theme.surface0
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Column {
            anchors {
                fill: parent
                margins: 20
            }
            spacing: 15

            // Header
            Item {
                width: parent.width
                height: 30

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Icon.github + " GitHub"
                    color: Theme.text
                    font.pixelSize: 18
                    font.bold: true
                    font.family: Config.moduleFontFamily
                }

                // Refresh button
                GhostButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32
                    radius: 16
                    icon: Icon.refresh
                    iconSize: 16
                    text: ""
                    onClicked: GitHubData.refresh()
                }
            }

            // Count summary
            Text {
                text: GitHubData.notificationCount + " unread notification" + (GitHubData.notificationCount !== 1 ? "s" : "")
                color: Theme.subtext0
                font.pixelSize: 12
                font.family: Config.moduleFontFamily
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.surface0
            }

            // Notifications list
            ScrollView {
                width: parent.width
                height: parent.height - 120
                clip: true

                Column {
                    width: parent.width
                    spacing: 10

                    Repeater {
                        model: GitHubData.notifications

                        Rectangle {
                            width: parent.width
                            height: notifColumn.implicitHeight + 20
                            radius: 8
                            color: modelData.unread ? Theme.surface0 : "transparent"
                            border.color: Theme.surface1
                            border.width: 1

                            Column {
                                id: notifColumn
                                anchors {
                                    fill: parent
                                    margins: 10
                                }
                                spacing: 6

                                // Title
                                Text {
                                    width: parent.width
                                    text: modelData.title
                                    color: Theme.text
                                    font.pixelSize: 13
                                    font.bold: modelData.unread
                                    font.family: Config.moduleFontFamily
                                    wrapMode: Text.WordWrap
                                }

                                // Repo and type
                                Row {
                                    spacing: 10

                                    Text {
                                        text: modelData.repo
                                        color: Theme.mauve
                                        font.pixelSize: 11
                                        font.family: Config.moduleFontFamily
                                    }

                                    Text {
                                        text: "•"
                                        color: Theme.overlay0
                                        font.pixelSize: 11
                                    }

                                    Text {
                                        text: modelData.type
                                        color: Theme.subtext0
                                        font.pixelSize: 11
                                        font.family: Config.moduleFontFamily
                                    }
                                }

                                // Time
                                Text {
                                    text: formatTime(modelData.updated_at)
                                    color: Theme.overlay1
                                    font.pixelSize: 10
                                    font.family: Config.moduleFontFamily
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.url) {
                                        Qt.openUrlExternally(modelData.url)
                                        AppState.toggleGitHubOverlay()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function formatTime(timestamp) {
        var date = new Date(timestamp)
        var now = new Date()
        var diff = Math.floor((now - date) / 1000) // seconds

        if (diff < 60) return "just now"
        if (diff < 3600) return Math.floor(diff / 60) + "m ago"
        if (diff < 86400) return Math.floor(diff / 3600) + "h ago"
        if (diff < 604800) return Math.floor(diff / 86400) + "d ago"
        return Math.floor(diff / 604800) + "w ago"
    }
}
