import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

// F5: the battery chip
PanelFrame {
    id: panel

    readonly property bool heldAtLimit: BatteryData.status === "Not charging" && BatteryData.chargeStop < 100

    readonly property string note: {
        if (heldAtLimit) return "held at charge limit"
        if (BatteryData.isFull) return "fully charged"
        if (BatteryData.timeText === "–") return ""
        return BatteryData.timeText + (BatteryData.isCharging ? " to full" : " left")
    }

    backTo: "control"
    spacing: 12

    Component.onCompleted: BatteryData.refresh()

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: BatteryData.refresh()
    }

    headerLeft: [
        IslandLabel {
            text: "Battery"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        IslandLabel {
            text: BatteryData.status.toLowerCase()
            kind: "meta"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    Row {
        spacing: 10

        IslandLabel {
            id: level
            text: BatteryData.capacity + "%"
            kind: "display"
            color: BatteryData.isLow ? Theme.warn : Theme.accentSky
        }

        IslandLabel {
            anchors.baseline: level.baseline
            text: panel.note
            kind: "meta"
        }
    }

    Item {
        width: parent.width
        height: 14

        BarSlider {
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            interactive: false
            thickness: 6
            fillColor: BatteryData.isLow ? Theme.warn : Theme.accentSky
            value: BatteryData.capacity
        }

        // Where charging stops
        Rectangle {
            visible: BatteryData.chargeStop < 100
            x: parent.width * BatteryData.chargeStop / 100 - width / 2
            width: 2
            height: parent.height
            radius: 1
            color: Theme.text
        }
    }

    Rectangle {
        width: parent.width
        height: facts.implicitHeight + 24
        radius: Config.cardRadius
        color: Theme.surfaceLow

        Grid {
            id: facts
            x: 14
            y: 12
            width: parent.width - 28
            columns: 2
            columnSpacing: 12
            rowSpacing: 5

            Repeater {
                model: [
                    { label: "Capacity", value: BatteryData.capacityText },
                    { label: "Charge limit", value: BatteryData.chargeStop + "%" },
                    { label: "Cycles", value: String(BatteryData.cycleCount) },
                    { label: "Time left", value: BatteryData.timeText }
                ]

                delegate: Item {
                    required property var modelData

                    width: (facts.width - facts.columnSpacing) / 2
                    height: 16

                    IslandLabel {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        kind: "meta"
                    }

                    IslandLabel {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.value
                        font.pixelSize: 11
                    }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 8

        IslandLabel { text: "Power profile"; kind: "meta" }

        SegmentedControl {
            width: parent.width
            options: BatteryData.profileNames
            currentIndex: BatteryData.profileIds.indexOf(BatteryData.profile)
            onActivated: index => BatteryData.setProfile(BatteryData.profileIds[index])
        }
    }
}
