import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

// F7: the Monitor tile
PanelFrame {
    id: panel

    backTo: "control"
    spacing: 8

    component GraphCard: Rectangle {
        id: card

        property string label: ""
        property string temperature: ""
        property bool hot: false
        property string usage: ""
        property var history: []
        property color lineColor: Theme.accentSky

        width: panel.bodyWidth
        height: 82
        radius: Config.cardRadius
        color: Theme.surfaceLow

        IslandLabel {
            x: 14
            y: 12
            text: card.label
            kind: "island"
        }

        Row {
            y: 12
            anchors.right: parent.right
            anchors.rightMargin: 14
            spacing: 14

            IslandLabel {
                visible: card.temperature !== ""
                text: card.temperature
                kind: "meta"
                color: card.hot ? Theme.warn : Theme.textDim
                anchors.verticalCenter: parent.verticalCenter
            }

            IslandLabel {
                text: card.usage
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Sparkline {
            x: 14
            y: 42
            width: parent.width - 28
            values: card.history
            lineColor: card.lineColor
        }
    }

    headerLeft: [
        IslandLabel {
            text: "System monitor"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        IslandLabel {
            text: SystemStatsData.windowSeconds + " s"
            kind: "meta"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    GraphCard {
        label: "CPU"
        temperature: SystemStatsData.cpuTemp + "°C"
        hot: SystemStatsData.cpuTemp >= 85
        usage: SystemStatsData.cpuUsage + "%"
        history: SystemStatsData.cpuHistory
    }

    GraphCard {
        label: "GPU"
        temperature: SystemStatsData.gpuTemp + "°C"
        hot: SystemStatsData.gpuTemp >= 85
        usage: SystemStatsData.gpuUsage + "%"
        history: SystemStatsData.gpuHistory
    }

    GraphCard {
        label: "Memory"
        usage: SystemStatsData.memoryUsage + "%"
        history: SystemStatsData.memoryHistory
        lineColor: Theme.accent
    }

    Row {
        width: parent.width
        spacing: 8

        MiniStat {
            width: (parent.width - parent.spacing) / 2
            label: "Network"
            value: "↓ " + SystemStatsData.networkSpeedDown + " ↑ " + SystemStatsData.networkSpeedUp
        }

        MiniStat {
            width: (parent.width - parent.spacing) / 2
            label: "NVMe SSD"
            value: SystemStatsData.nvmeTemp + "°C"
            valueColor: SystemStatsData.nvmeTemp >= 70 ? Theme.warn : Theme.text
        }
    }
}
