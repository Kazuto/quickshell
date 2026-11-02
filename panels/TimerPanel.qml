import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"
import "root:/js/KeyNav.js" as KeyNav

// D: click the timer bubble, or Custom… in quick access. Digits set minutes.
PanelFrame {
    id: panel

    readonly property var presets: [1, 5, 10, 15, 25, 30]
    property int pendingMinutes: TimerData.totalSeconds > 0 ? Math.round(TimerData.totalSeconds / 60) : 5
    property string typedMinutes: ""

    readonly property bool hasTimer: TimerData.running

    function primaryAction() {
        if (!hasTimer) TimerData.start(pendingMinutes)
        else if (TimerData.isPaused) TimerData.resume()
        else TimerData.pause()
    }

    headerLeft: [
        TimerRing {
            progress: panel.hasTimer ? TimerData.progress : 1
            anchors.verticalCenter: parent.verticalCenter
        },
        IslandLabel {
            text: "Timer"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        IslandLabel {
            visible: panel.hasTimer
            text: "of " + TimerData.formatTime(TimerData.totalSeconds)
            kind: "meta"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    IslandLabel {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: panel.hasTimer ? TimerData.displayTime : TimerData.formatTime(panel.pendingMinutes * 60)
        kind: "display"
        color: panel.hasTimer ? Theme.accentSky : Theme.text
    }

    BarSlider {
        width: parent.width
        interactive: false
        thickness: 4
        fillColor: Theme.accentSky
        value: (panel.hasTimer ? TimerData.progress : 1) * 100
    }

    Row {
        width: parent.width
        spacing: 8

        Repeater {
            model: panel.presets

            delegate: IslandButton {
                required property var modelData

                width: (parent.width - 5 * parent.spacing) / 6
                implicitHeight: 36
                radius: Config.controlRadius
                label: modelData + "m"
                variant: panel.pendingMinutes === modelData ? "selected" : "raised"
                onClicked: {
                    panel.typedMinutes = ""
                    panel.pendingMinutes = modelData
                    if (panel.hasTimer) TimerData.start(modelData)
                }
            }
        }
    }

    Row {
        width: parent.width
        spacing: 8

        IslandButton {
            width: (parent.width - parent.spacing) / 2
            label: "Reset"
            active: panel.hasTimer
            onClicked: TimerData.stop()
        }

        IslandButton {
            width: (parent.width - parent.spacing) / 2
            label: !panel.hasTimer ? "Start" : TimerData.isPaused ? "Resume" : "Pause"
            variant: "sky"
            onClicked: panel.primaryAction()
        }
    }

    function handleKey(event) {
        if (KeyNav.isConfirm(event) || event.key === Qt.Key_Space) {
            primaryAction()
        } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9 && !hasTimer) {
            typedMinutes = (typedMinutes + event.text).slice(-3)
            pendingMinutes = Math.max(1, parseInt(typedMinutes, 10) || 1)
        } else if (KeyNav.isBackspace(event)) {
            typedMinutes = typedMinutes.slice(0, -1)
        } else {
            return
        }
        event.accepted = true
    }
}
