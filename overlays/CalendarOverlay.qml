import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/components"

PanelWindow {
    id: calendarOverlay

    property date currentDate: new Date()
    property int displayMonth: currentDate.getMonth()
    property int displayYear: currentDate.getFullYear()

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
        onClicked: AppState.toggleCalendarOverlay()
        z: -1
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 12
            rightMargin: 20
        }
        width: 350
        height: 420
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

            // Header with month/year and navigation
            Item {
                width: parent.width
                height: 35

                // Previous month button
                GhostButton {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32
                    radius: 16
                    icon: "‹"
                    iconSize: 20
                    text: ""
                    onClicked: {
                        displayMonth--
                        if (displayMonth < 0) {
                            displayMonth = 11
                            displayYear--
                        }
                        calendarGrid.model = 0
                        calendarGrid.model = 42
                    }
                }

                // Month and year display
                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDate(new Date(displayYear, displayMonth, 1), "MMMM yyyy")
                    color: Theme.text
                    font.pixelSize: 16
                    font.bold: true
                    font.family: Config.moduleFontFamily
                }

                // Next month button
                GhostButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32
                    radius: 16
                    icon: "›"
                    iconSize: 20
                    text: ""
                    onClicked: {
                        displayMonth++
                        if (displayMonth > 11) {
                            displayMonth = 0
                            displayYear++
                        }
                        calendarGrid.model = 0
                        calendarGrid.model = 42
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.surface0
            }

            // Weekday headers
            Grid {
                width: parent.width
                columns: 7
                spacing: 0

                Repeater {
                    model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

                    Rectangle {
                        width: (parent.width - parent.spacing * 6) / 7
                        height: 30
                        color: "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: Theme.subtext0
                            font.pixelSize: 11
                            font.bold: true
                            font.family: Config.moduleFontFamily
                        }
                    }
                }
            }

            // Calendar grid
            Grid {
                id: calendarGrid
                width: parent.width
                columns: 7
                spacing: 4

                Repeater {
                    model: 42  // 6 weeks * 7 days

                    delegate: Rectangle {
                        property date cellDate: {
                            var firstDay = new Date(displayYear, displayMonth, 1)
                            var dayOfWeek = firstDay.getDay()
                            var dayNum = index - dayOfWeek + 1
                            return new Date(displayYear, displayMonth, dayNum)
                        }
                        property bool isCurrentMonth: cellDate.getMonth() === displayMonth
                        property bool isToday: {
                            var today = new Date()
                            return cellDate.getDate() === today.getDate() &&
                                   cellDate.getMonth() === today.getMonth() &&
                                   cellDate.getFullYear() === today.getFullYear()
                        }

                        width: (parent.width - parent.spacing * 6) / 7
                        height: 38
                        radius: 8
                        color: isToday ? Theme.blue :
                               (dayMouseArea.containsMouse ? Theme.surface1 : "transparent")
                        border.color: isToday ? Theme.blue : "transparent"
                        border.width: isToday ? 2 : 0

                        Text {
                            anchors.centerIn: parent
                            text: cellDate.getDate()
                            color: isToday ? Theme.base :
                                   (isCurrentMonth ? Theme.text : Theme.overlay0)
                            font.pixelSize: 13
                            font.bold: isToday
                            font.family: Config.moduleFontFamily
                        }

                        MouseArea {
                            id: dayMouseArea
                            anchors.fill: parent
                            hoverEnabled: isCurrentMonth
                            cursorShape: isCurrentMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (isCurrentMonth) {
                                    console.log("Selected date:", cellDate)
                                }
                            }
                        }
                    }
                }
            }

            // Current date display
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(currentDate, "dddd, MMMM d, yyyy")
                color: Theme.subtext0
                font.pixelSize: 12
                font.family: Config.moduleFontFamily
            }
        }
    }

    Timer {
        interval: 60000  // Update every minute
        running: true
        repeat: true
        onTriggered: currentDate = new Date()
    }
}
