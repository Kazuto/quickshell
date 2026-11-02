import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"
import "root:/js/KeyNav.js" as KeyNav

// E: the Record tile in the control center
PanelFrame {
    id: panel

    readonly property var captureValues: ["screen", "window", "area"]
    readonly property var audioValues: ["both", "system", "mic", "none"]
    readonly property var qualityValues: ["high", "medium", "low"]

    spacing: 12

    function toggleRecording() {
        if (RecorderData.recording) RecorderData.stop()
        else RecorderData.start()
    }

    function handleKey(event) {
        if (!KeyNav.isConfirm(event)) return
        toggleRecording()
        event.accepted = true
    }

    headerLeft: [
        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: RecorderData.recording ? Theme.rec : Theme.textFaint
            anchors.verticalCenter: parent.verticalCenter
        },
        IslandLabel {
            text: "Screen recorder"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        IslandLabel {
            text: RecorderData.recording ? "REC " + RecorderData.elapsedText : "ready"
            kind: "meta"
            color: RecorderData.recording ? Theme.rec : Theme.textDim
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    Column {
        width: parent.width
        spacing: 8

        IslandLabel { text: "Capture"; kind: "meta" }

        SegmentedControl {
            width: parent.width
            active: !RecorderData.recording
            options: ["Screen", "Window", "Area"]
            currentIndex: panel.captureValues.indexOf(RecorderData.captureMode)
            onActivated: index => RecorderData.captureMode = panel.captureValues[index]
        }
    }

    Column {
        width: parent.width
        spacing: 8

        IslandLabel { text: "Audio"; kind: "meta" }

        SegmentedControl {
            width: parent.width
            active: !RecorderData.recording
            options: ["Sys+Mic", "System", "Mic", "None"]
            currentIndex: panel.audioValues.indexOf(RecorderData.audioMode)
            onActivated: index => RecorderData.audioMode = panel.audioValues[index]
        }
    }

    Column {
        width: parent.width
        spacing: 8

        IslandLabel { text: "Quality"; kind: "meta" }

        SegmentedControl {
            width: parent.width
            active: !RecorderData.recording
            options: ["High", "Medium", "Low"]
            currentIndex: panel.qualityValues.indexOf(RecorderData.quality)
            onActivated: index => RecorderData.quality = panel.qualityValues[index]
        }
    }

    Row {
        width: parent.width
        spacing: 12
        topPadding: 4

        IslandButton {
            width: parent.width - 44 - parent.spacing
            variant: "rec"
            leadingDot: !RecorderData.recording
            label: RecorderData.recording ? "Stop recording" : "Start recording"
            onClicked: panel.toggleRecording()
        }

        IslandButton {
            iconName: "folder"
            onClicked: RecorderData.openFolder()
        }
    }
}
