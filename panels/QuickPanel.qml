import QtQuick
import Quickshell
import "root:/"
import "root:/singletons"
import "root:/components"
import "root:/js/KeyNav.js" as KeyNav

// K3: every action in one grid of four columns
PanelFrame {
    id: panel

    property string filterText: ""
    property int selectedIndex: 0

    readonly property int columns: 4
    readonly property int tileWidth: (bodyWidth - (columns - 1) * 8) / columns

    readonly property var actions: [
        { id: "record-screen", section: "capture", label: "Record screen", hint: "1" },
        { id: "record-area", section: "capture", label: "Record area", hint: "2" },
        { id: "shot-area", section: "capture", label: "Screenshot area", hint: "3" },
        { id: "shot-output", section: "capture", label: "Screenshot output", hint: "4" },
        { id: "timer-5", section: "timer", label: "5 min", minutes: 5 },
        { id: "timer-15", section: "timer", label: "15 min", minutes: 15 },
        { id: "timer-25", section: "timer", label: "25 min", minutes: 25 },
        { id: "timer-custom", section: "timer", label: "Custom…" },
        { id: "color-picker", section: "tools", label: "Color picker" },
        { id: "clipboard", section: "tools", label: "Clipboard" },
        { id: "dnd", section: "tools", label: "Do not disturb" },
        { id: "wallpaper", section: "tools", label: "Wallpaper" }
    ]

    panelWidth: Config.panelWideWidth
    bodyInset: 14
    bodyTopGap: 10
    spacing: 12

    function sectionItems(section) {
        return actions.filter(function(a) { return a.section === section })
    }

    function matches(action) {
        return filterText === "" || action.label.toLowerCase().indexOf(filterText.toLowerCase()) >= 0
    }

    onFilterTextChanged: {
        for (var i = 0; i < actions.length; i++) {
            if (matches(actions[i])) {
                selectedIndex = i
                return
            }
        }
    }

    function delayedShot(args) {
        // Long enough for the panel and scrim to be gone from the capture
        Quickshell.execDetached(["sh", "-c", "sleep 0.4; grimblast --notify copy " + args])
    }

    function run(action) {
        if (!action) return
        switch (action.id) {
        case "record-screen": RecorderData.start("screen"); break
        case "record-area": RecorderData.start("area"); break
        case "shot-area": AppState.closePanel(); delayedShot("area"); break
        case "shot-output": AppState.closePanel(); delayedShot("output"); break
        case "timer-custom": AppState.openPanel("timer"); break
        case "color-picker":
            AppState.closePanel()
            Quickshell.execDetached(["sh", "-c", "sleep 0.4; hyprpicker -a -n"])
            break
        case "clipboard": AppState.openPanel("clipboard"); break
        case "dnd": NotificationData.togglePause(); break
        case "wallpaper": AppState.openPanel("wallpaper"); break
        default:
            TimerData.start(action.minutes)
            AppState.closePanel()
        }
    }

    function moveSelection(delta) {
        var next = selectedIndex + delta
        if (next >= 0 && next < actions.length) selectedIndex = next
    }

    function handleKey(event) {
        if (event.key >= Qt.Key_1 && event.key <= Qt.Key_4) {
            run(actions[event.key - Qt.Key_1])
        } else if (KeyNav.isConfirm(event)) {
            run(actions[selectedIndex])
        } else if (KeyNav.isPrevColumn(event)) {
            moveSelection(-1)
        } else if (KeyNav.isNextColumn(event)) {
            moveSelection(1)
        } else if (KeyNav.isPrev(event)) {
            moveSelection(-columns)
        } else if (KeyNav.isNext(event)) {
            moveSelection(columns)
        } else if (KeyNav.isBackspace(event)) {
            if (filterText.length > 0) filterText = filterText.slice(0, -1)
        } else if (KeyNav.isPrintableChar(event)) {
            filterText += event.text
        } else {
            return
        }
        event.accepted = true
    }

    headerLeft: [
        SearchField {
            width: panel.headerWidth - chip.width - 12
            text: panel.filterText
            placeholder: "Run an action…"
            iconName: "lightning"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        KeyChip {
            id: chip
            text: HotkeyData.keyFor("quick-toggle", "Super Q")
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    Column {
        width: parent.width
        spacing: 8

        IslandLabel { text: "Capture"; kind: "meta" }

        Row {
            spacing: 8

            Repeater {
                model: panel.sectionItems("capture")

                delegate: ActionTile {
                    required property var modelData
                    required property int index

                    action: modelData
                    actionIndex: index
                    width: panel.tileWidth
                    height: 88

                    Item {
                        x: 12
                        y: 12
                        width: 16
                        height: 16

                        Rectangle {
                            anchors.centerIn: parent
                            visible: modelData.id === "record-screen" || modelData.id === "record-area"
                            width: modelData.id === "record-area" ? 5 : 12
                            height: width
                            radius: width / 2
                            color: Theme.rec
                        }

                        SvgIcon {
                            visible: modelData.id !== "record-screen"
                            name: modelData.id === "shot-output" ? "monitor" : "frame-corners"
                            size: 16
                            color: Theme.text
                        }
                    }

                    Column {
                        x: 12
                        y: 44
                        width: parent.width - 24
                        spacing: 2

                        IslandLabel {
                            width: parent.width
                            text: modelData.label
                            kind: "island"
                        }

                        IslandLabel {
                            text: modelData.hint
                            kind: "meta"
                        }
                    }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 8

        IslandLabel { text: "Timer"; kind: "meta" }

        Row {
            spacing: 8

            Repeater {
                model: panel.sectionItems("timer")

                delegate: ActionTile {
                    required property var modelData
                    required property int index

                    action: modelData
                    actionIndex: 4 + index
                    width: panel.tileWidth
                    height: 44

                    IslandLabel {
                        anchors.centerIn: parent
                        text: modelData.label
                        kind: modelData.minutes ? "island" : "body"
                        color: modelData.minutes ? Theme.accentSky : Theme.textDim
                    }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 8

        IslandLabel { text: "Tools"; kind: "meta" }

        Row {
            spacing: 8

            Repeater {
                model: panel.sectionItems("tools")

                delegate: ActionTile {
                    required property var modelData
                    required property int index

                    action: modelData
                    actionIndex: 8 + index
                    width: panel.tileWidth
                    height: 44

                    IslandLabel {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: modelData.id === "dnd" && NotificationData.paused ? Theme.accent : Theme.text
                    }
                }
            }
        }
    }

    HintRow {
        x: 8
        width: parent.width - 16
        hints: ["1-4 run capture", "↵ run", "←→↑↓ move"]
    }
}
