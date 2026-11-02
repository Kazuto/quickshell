import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"
import "root:/js/KeyNav.js" as KeyNav

// K4: read from hyprland.conf, so it can't drift from what the keys really do
PanelFrame {
    id: panel

    property string filterText: ""
    property double openedAt: Date.now()

    // Left and right columns of the sheet, by section title
    readonly property var leftTitles: ["Overlays", "Workspaces", "Tools"]
    readonly property int columnWidth: (bodyWidth - 24) / 2

    panelWidth: Config.panelWideWidth
    bodyInset: 22
    bodyTopGap: 12
    spacing: 12

    function column(isLeft) {
        var query = filterText.trim().toLowerCase()
        var result = []
        var sections = HotkeyData.sections
        for (var i = 0; i < sections.length; i++) {
            if ((leftTitles.indexOf(sections[i].title) >= 0) !== isLeft) continue
            var rows = sections[i].rows.filter(function(row) {
                return !query || row.label.toLowerCase().indexOf(query) >= 0
                    || row.keys.toLowerCase().indexOf(query) >= 0
            })
            if (rows.length > 0) result.push({ title: sections[i].title, rows: rows })
        }
        return result
    }

    function handleKey(event) {
        if (KeyNav.isBackspace(event)) {
            if (filterText.length > 0) filterText = filterText.slice(0, -1)
        } else if (KeyNav.isPrintableChar(event)) {
            filterText += event.text
        } else {
            return
        }
        event.accepted = true
    }

    // Holding the chord peeks at the sheet and letting go closes it. A quick tap
    // leaves it open, since typing to filter isn't possible with Super held.
    function handleKeyRelease(event) {
        if (event.key !== Qt.Key_Super_L && event.key !== Qt.Key_Super_R && event.key !== Qt.Key_Meta) return
        if (Date.now() - openedAt > 350) AppState.closePanel()
        event.accepted = true
    }

    headerLeft: [
        SvgIcon {
            name: "keyboard"
            size: 16
            color: Theme.text
            anchors.verticalCenter: parent.verticalCenter
        },
        IslandLabel {
            text: "Hotkeys"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        },
        IslandLabel {
            text: panel.filterText !== "" ? panel.filterText : "read from hyprland.conf"
            kind: "meta"
            color: panel.filterText !== "" ? Theme.text : Theme.textDim
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        KeyChip {
            text: HotkeyData.keyFor("hotkeys-toggle", "Super /")
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    Row {
        width: parent.width
        spacing: 24

        Repeater {
            model: [true, false]

            delegate: Column {
                required property var modelData

                width: panel.columnWidth
                spacing: 12

                Repeater {
                    model: panel.column(modelData)

                    delegate: Column {
                        required property var modelData

                        width: panel.columnWidth
                        spacing: 0

                        IslandLabel {
                            height: 20
                            text: modelData.title.toUpperCase()
                            kind: "island"
                            color: Theme.accent
                            font.pixelSize: 10
                            font.letterSpacing: 1
                        }

                        Repeater {
                            model: modelData.rows

                            delegate: Item {
                                required property var modelData

                                width: panel.columnWidth
                                height: 28

                                IslandLabel {
                                    width: parent.width - keyChip.width - 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    font.pixelSize: 11
                                }

                                KeyChip {
                                    id: keyChip
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.keys
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    HintRow {
        width: parent.width
        hints: ["Type to filter"]
        trailing: "Esc or release Super to close"
    }
}
