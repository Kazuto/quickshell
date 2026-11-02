import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"
import "root:/js/KeyNav.js" as KeyNav

// K2
PanelFrame {
    id: panel

    property string filterText: ""
    property int selectedIndex: 0
    property string tab: "recent"
    property var results: []

    readonly property var tabs: [
        { id: "recent", label: "Recent" },
        { id: "smileys", label: "Smileys" },
        { id: "people", label: "People" },
        { id: "symbols", label: "Symbols" },
        { id: "kaomoji", label: "Kaomoji" }
    ]
    readonly property bool wideCells: tab === "kaomoji" && filterText === ""
    readonly property int columns: wideCells ? 4 : 10
    readonly property int rows: tab === "recent" && filterText === "" ? 2 : 4
    readonly property var selected: results[selectedIndex] || null

    panelWidth: Config.panelWideWidth
    bodyInset: 14
    bodyTopGap: 10
    spacing: 10

    function rebuild() {
        var query = filterText.trim().toLowerCase()
        var list = EmojiData.emojis
        var result = []
        var i
        if (query) {
            for (i = 0; i < list.length; i++) {
                if (list[i].name.toLowerCase().indexOf(query) >= 0
                    || list[i].keywords.toLowerCase().indexOf(query) >= 0) result.push(list[i])
            }
        } else if (tab === "recent") {
            for (i = 0; i < list.length; i++) {
                if (EmojiData.usageOf(list[i].glyph) > 0) result.push(list[i])
            }
            result.sort(function(a, b) { return EmojiData.usageOf(b.glyph) - EmojiData.usageOf(a.glyph) })
            // Nothing used yet: start from the first smileys rather than an empty grid
            for (i = 0; i < list.length && result.length < 20; i++) {
                if (list[i].category === "smileys" && result.indexOf(list[i]) < 0) result.push(list[i])
            }
            result = result.slice(0, 20)
        } else {
            for (i = 0; i < list.length; i++) {
                if (list[i].category === tab) result.push(list[i])
            }
        }
        results = result
        selectedIndex = 0
        grid.positionViewAtBeginning()
    }

    onFilterTextChanged: rebuild()
    onTabChanged: rebuild()
    Component.onCompleted: rebuild()

    Connections {
        target: EmojiData
        function onLoadedChanged() { panel.rebuild() }
        function onUsageLoadedChanged() { panel.rebuild() }
    }

    function commit(entry, copyOnly) {
        if (!entry) return
        AppState.closePanel()
        EmojiData.commit(entry.glyph, copyOnly)
    }

    function moveSelection(delta) {
        var next = selectedIndex + delta
        if (next < 0 || next >= results.length) return
        selectedIndex = next
        grid.positionViewAtIndex(next, GridView.Contain)
    }

    function nextTab() {
        for (var i = 0; i < tabs.length; i++) {
            if (tabs[i].id === tab) {
                tab = tabs[(i + 1) % tabs.length].id
                return
            }
        }
    }

    function handleKey(event) {
        if (KeyNav.isConfirm(event)) {
            commit(selected, (event.modifiers & Qt.ShiftModifier) !== 0)
        } else if (KeyNav.isPrevColumn(event)) {
            moveSelection(-1)
        } else if (KeyNav.isNextColumn(event)) {
            moveSelection(1)
        } else if (KeyNav.isPrev(event)) {
            moveSelection(-columns)
        } else if (KeyNav.isNext(event)) {
            moveSelection(columns)
        } else if (event.key === Qt.Key_Tab) {
            nextTab()
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
            placeholder: "Search emoji…"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        KeyChip {
            id: chip
            text: HotkeyData.keyFor("emoji-toggle", "Super .")
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    Row {
        spacing: 6
        opacity: panel.filterText === "" ? 1 : 0.5

        Repeater {
            model: panel.tabs

            delegate: FilterChip {
                required property var modelData

                label: modelData.label
                selected: panel.tab === modelData.id
                onClicked: {
                    panel.filterText = ""
                    panel.tab = modelData.id
                }
            }
        }
    }

    GridView {
        id: grid

        width: parent.width
        height: panel.rows * cellHeight
        cellWidth: Math.floor(width / panel.columns)
        cellHeight: panel.wideCells ? 44 : 60
        model: panel.results
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        delegate: Item {
            id: cell

            required property int index
            required property var modelData

            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: Config.controlRadius
                color: cell.index === panel.selectedIndex ? Theme.surfaceHigh : "transparent"
            }

            Text {
                anchors.centerIn: parent
                text: cell.modelData.glyph
                color: Theme.text
                font.pixelSize: panel.wideCells ? 12 : 24
                font.family: panel.wideCells ? Config.moduleFontFamily : font.family
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: panel.selectedIndex = cell.index
                onClicked: panel.commit(cell.modelData, false)
            }
        }

        IslandLabel {
            anchors.centerIn: parent
            visible: panel.results.length === 0
            text: EmojiData.loaded ? "No matching emoji" : "Loading…"
            kind: "meta"
        }
    }

    Item {
        x: 8
        width: parent.width - 16
        height: 18

        IslandLabel {
            width: parent.width - hints.implicitWidth - 16
            anchors.verticalCenter: parent.verticalCenter
            text: panel.selected ? panel.selected.name : ""
            kind: "meta"
            color: Theme.text
        }

        Row {
            id: hints
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16

            IslandLabel { text: "↵ type"; kind: "meta" }
            IslandLabel { text: "Shift ↵ copy"; kind: "meta" }
            IslandLabel { text: "Esc close"; kind: "meta" }
        }
    }
}
