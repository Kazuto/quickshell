import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

// C: click the clock
PanelFrame {
    id: panel

    readonly property var today: IslandData.now
    property int year: today.getFullYear()
    property int month: today.getMonth()

    readonly property int weekColumn: 36
    readonly property int dayColumn: 52
    readonly property var dayNames: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    function shiftMonth(delta) {
        var d = new Date(year, month + delta, 1)
        year = d.getFullYear()
        month = d.getMonth()
    }

    function backToToday() {
        year = today.getFullYear()
        month = today.getMonth()
    }

    function isoWeek(date) {
        var d = new Date(date.getFullYear(), date.getMonth(), date.getDate())
        d.setDate(d.getDate() + 3 - (d.getDay() + 6) % 7)
        var firstThursday = new Date(d.getFullYear(), 0, 4)
        return 1 + Math.round(((d - firstThursday) / 86400000 - 3 + (firstThursday.getDay() + 6) % 7) / 7)
    }

    // Header row plus six weeks, each led by its week number. Always six rows
    // so the panel keeps its height while paging through months.
    readonly property var cells: {
        var result = [{ text: "KW", kind: "head" }]
        for (var i = 0; i < 7; i++) result.push({ text: dayNames[i], kind: "head" })

        var first = new Date(year, month, 1)
        var cursor = new Date(year, month, 1 - (first.getDay() + 6) % 7)
        for (var week = 0; week < 6; week++) {
            result.push({ text: isoWeek(cursor), kind: "week" })
            for (var day = 0; day < 7; day++) {
                result.push({
                    text: cursor.getDate(),
                    kind: "day",
                    outside: cursor.getMonth() !== month,
                    isToday: cursor.getFullYear() === today.getFullYear()
                        && cursor.getMonth() === today.getMonth()
                        && cursor.getDate() === today.getDate()
                })
                cursor.setDate(cursor.getDate() + 1)
            }
        }
        return result
    }

    headerLeft: [
        IslandLabel {
            text: IslandData.clockText
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        },
        IslandLabel {
            text: Qt.formatDateTime(panel.today, "dddd, d MMMM")
            color: Theme.textDim
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    Item {
        width: parent.width
        height: 32

        IslandButton {
            implicitHeight: 32
            iconName: "caret-left"
            iconSize: 12
            onClicked: panel.shiftMonth(-1)
        }

        IslandLabel {
            anchors.centerIn: parent
            text: Qt.formatDate(new Date(panel.year, panel.month, 1), "MMMM yyyy")
            kind: "island"
            font.pixelSize: 13

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: panel.backToToday()
            }
        }

        IslandButton {
            anchors.right: parent.right
            implicitHeight: 32
            iconName: "caret-right"
            iconSize: 12
            onClicked: panel.shiftMonth(1)
        }
    }

    Grid {
        width: parent.width
        columns: 8

        Repeater {
            model: panel.cells

            delegate: Item {
                required property int index
                required property var modelData

                width: index % 8 === 0 ? panel.weekColumn : panel.dayColumn
                height: modelData.kind === "head" ? 24 : 40

                Rectangle {
                    anchors.centerIn: parent
                    visible: modelData.isToday === true
                    width: 44
                    height: 34
                    radius: Config.controlRadius
                    color: Theme.accent
                }

                IslandLabel {
                    anchors.centerIn: parent
                    text: modelData.text
                    kind: modelData.kind === "day" ? (modelData.isToday ? "island" : "body") : "meta"
                    color: {
                        if (modelData.isToday) return Theme.textOnAccent
                        if (modelData.kind === "day") return modelData.outside ? Theme.textFaint : Theme.text
                        return Theme.textDim
                    }
                }
            }
        }

        WheelHandler {
            onWheel: event => panel.shiftMonth(event.angleDelta.y > 0 ? -1 : 1)
        }
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Left) shiftMonth(-1)
        else if (event.key === Qt.Key_Right) shiftMonth(1)
        else if (event.key === Qt.Key_Home) backToToday()
        else return
        event.accepted = true
    }
}
