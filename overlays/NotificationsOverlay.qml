import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/singletons"
import "root:/components"

PanelWindow {
    id: notificationsOverlay

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
            NotificationData.refresh()
        }
    }

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: AppState.toggleNotificationsOverlay()
        z: -1
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 12
            rightMargin: Math.min(AppState.screenWidth - 400 - 10, Math.max(10, AppState.screenWidth - AppState.lastClickX - 400 / 2))  // Position overlay near Notifications module (rightmost)
        }
        width: 400
        height: Math.min(700, parent.height - Config.barHeight - Config.barMarginTop - 40)
        color: Theme.mantle
        radius: Config.overlayRadius
        border.color: Theme.surface0
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: {} // Prevent clicks from passing through
        }

        Column {
            id: headerColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 20
            }
            spacing: 15

            // Header
            Item {
                width: parent.width
                height: 30

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    SvgIcon { name: "bell"; size: 16; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Notifications"; color: Theme.text; font.pixelSize: 16; font.bold: true; font.family: Config.moduleFontFamily }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    // Pause toggle
                    Row {
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "Notify"
                            color: Theme.subtext0
                            font.pixelSize: 12
                            font.family: Config.moduleFontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Toggle {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: !NotificationData.paused
                            onColor: Theme.yellow
                            onToggled: NotificationData.togglePause()
                        }
                    }

                    // Clear all button
                    GhostButton {
                        width: 80
                        height: 30
                        radius: 15
                        text: "Clear All"
                        fontSize: 12
                        onClicked: NotificationData.clearAll()
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.surface0
            }
        }

        // Scrollable notifications area
        Flickable {
            anchors {
                top: headerColumn.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 20
                topMargin: 10
            }
            contentHeight: notificationsColumn.implicitHeight
            clip: true

            Column {
                id: notificationsColumn
                width: parent.width
                spacing: 10

                // Empty state
                Item {
                    width: parent.width
                    height: 100
                    visible: NotificationData.notifications.length === 0

                    Text {
                        anchors.centerIn: parent
                        text: "No notifications"
                        color: Theme.overlay0
                        font.pixelSize: 14
                        font.family: Config.moduleFontFamily
                    }
                }

                // Notifications list
                Repeater {
                    model: NotificationData.notifications

                    Rectangle {
                        width: parent.width
                        height: notifContent.implicitHeight + 20
                        color: notifMouseArea.containsMouse ? Theme.surface1 : Theme.surface0
                        radius: Config.moduleRadius

                        Row {
                            id: notifContent
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 15
                            }
                            spacing: 15

                            Column {
                                width: parent.width - 50
                                spacing: 5

                                Text {
                                    width: parent.width
                                    text: modelData.summary
                                    color: Theme.text
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.family: Config.moduleFontFamily
                                    elide: Text.ElideRight
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                }

                                Text {
                                    width: parent.width
                                    text: modelData.body.replace(/<[^>]*>/g, '')  // Strip HTML tags
                                    color: Theme.subtext0
                                    font.pixelSize: 12
                                    font.family: Config.moduleFontFamily
                                    elide: Text.ElideRight
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                }

                                Text {
                                    text: modelData.appname
                                    color: Theme.overlay0
                                    font.pixelSize: 10
                                    font.family: Config.moduleFontFamily
                                }
                            }

                            // Close button
                            Text {
                                text: ""
                                color: closeMouseArea.containsMouse ? Theme.red : Theme.overlay0
                                font.pixelSize: 18
                                font.family: Config.moduleFontFamily

                                MouseArea {
                                    id: closeMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        NotificationData.closeNotification(modelData.id)
                                        mouse.accepted = true
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: notifMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            z: -1
                        }
                    }
                }
            }
        }
    }
}
