import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "root:/"
import "root:/singletons"
import "root:/components"
import "root:/js/KeyNav.js" as KeyNav

PanelWindow {
    id: root

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // ── State ──────────────────────────────────────────────────────────────
    property string filterText: ""
    property int selectedIndex: 0
    property var filteredEmojis: []
    property string toastMessage: ""

    readonly property int columns: 8
    readonly property int cellSize: 56
    readonly property int sidePadding: 18

    function buildFiltered() {
        var query = filterText.trim().toLowerCase()
        var result = []
        var list = EmojiData.emojis
        for (var i = 0; i < list.length; i++) {
            var e = list[i]
            if (!query
                || e.name.toLowerCase().indexOf(query) >= 0
                || e.keywords.toLowerCase().indexOf(query) >= 0) {
                result.push({ entry: e, originalIndex: i })
            }
        }
        // Most-used emoji first; ties fall back to original data order.
        result.sort(function(a, b) {
            var countA = EmojiData.usageOf(a.entry.glyph)
            var countB = EmojiData.usageOf(b.entry.glyph)
            if (countA !== countB) return countB - countA
            return a.originalIndex - b.originalIndex
        })
        filteredEmojis = result.map(function(r) { return r.entry })
        selectedIndex = filteredEmojis.length > 0 ? 0 : -1
    }

    onFilterTextChanged: buildFiltered()

    Connections {
        target: EmojiData
        function onLoadedChanged() { root.buildFiltered() }
        function onUsageLoadedChanged() { root.buildFiltered() }
    }

    // ── Copy + type + close ──────────────────────────────────────────────
    property string pendingGlyph: ""

    function commitEntry(entry) {
        if (!entry) return
        pendingGlyph = entry.glyph
        EmojiData.recordUsage(entry.glyph)
        // Also put it on the clipboard as a fallback for manual paste
        Qt.createQmlObject(
            'import Quickshell.Io; Process { command: ["wl-copy", ' + JSON.stringify(entry.glyph) + ']; running: true }',
            root
        )
        closeOverlay()
        // Give the compositor a moment to restore focus to the previous
        // window before typing the emoji into it.
        typeTimer.restart()
    }

    function commitSelected() {
        if (selectedIndex < 0 || selectedIndex >= filteredEmojis.length) return
        commitEntry(filteredEmojis[selectedIndex])
    }

    Timer {
        id: typeTimer
        interval: 180
        repeat: false
        onTriggered: {
            if (!root.pendingGlyph) return
            // Simulate Ctrl+V rather than typing raw Unicode keystrokes —
            // Chromium/Electron apps (Slack, browsers) don't reliably accept
            // synthetic emoji keysyms from wtype, but a real paste works
            // everywhere since the emoji is already on the clipboard.
            Qt.createQmlObject(
                'import Quickshell.Io; Process { command: ["wtype", "-M", "ctrl", "-k", "v", "-m", "ctrl"]; running: true }',
                root
            )
            root.pendingGlyph = ""
        }
    }

    function closeOverlay() {
        filterText = ""
        AppState.emojiPickerOverlayVisible = false
    }

    // ── Keyboard handling ──────────────────────────────────────────────────
    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (KeyNav.isEscape(event)) {
                root.closeOverlay()
                event.accepted = true

                return
            }

            if (KeyNav.isConfirm(event)) {
                root.commitSelected()
                event.accepted = true

                return
            }

            if (KeyNav.isPrevColumn(event)) {
                if (root.selectedIndex > 0) root.selectedIndex--
                event.accepted = true

                return
            }

            if (KeyNav.isNextColumn(event)) {
                if (root.selectedIndex < root.filteredEmojis.length - 1) root.selectedIndex++
                event.accepted = true

                return
            }

            if (KeyNav.isPrev(event)) {
                if (root.selectedIndex - root.columns >= 0) root.selectedIndex -= root.columns
                event.accepted = true

                return
            }

            if (KeyNav.isNext(event)) {
                if (root.selectedIndex + root.columns < root.filteredEmojis.length)
                    root.selectedIndex += root.columns
                event.accepted = true

                return
            }

            if (KeyNav.isBackspace(event)) {
                if (root.filterText.length > 0)
                    root.filterText = root.filterText.slice(0, -1)
                event.accepted = true

                return
            }

            if (KeyNav.isPrintableChar(event)) {
                root.filterText += event.text
                event.accepted = true
            }
        }
    }

    // ── Scrim ──────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Config.alpha(Theme.crust, 0.6)

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeOverlay()
        }
    }

    // ── Card ───────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        width: root.columns * root.cellSize + root.sidePadding * 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        readonly property int gridTopSpacing: 10
        readonly property int maxGridHeight: root.cellSize * 6
        readonly property int gridHeight: Math.ceil(root.filteredEmojis.length / root.columns) * root.cellSize
        readonly property int visibleGridHeight: Math.max(
            Math.min(gridHeight, maxGridHeight),
            root.filteredEmojis.length === 0 ? root.cellSize * 2 : 0
        )

        height: searchRow.height + 1 + gridTopSpacing + visibleGridHeight + 14

        color: Theme.base
        radius: 12
        border.color: Theme.surface1
        border.width: 1

        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
            anchors.fill: parent

            // ── Search row ─────────────────────────────────────────────────
            Row {
                id: searchRow
                width: parent.width
                height: 54
                leftPadding: root.sidePadding
                rightPadding: root.sidePadding
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf002"   // magnifying glass
                    color: Theme.subtext0
                    font.pixelSize: 16
                    font.family: Config.moduleFontFamily
                }

                Item {
                    width: parent.width - 40
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: filterTextItem
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        text: root.filterText
                        color: Theme.text
                        font.pixelSize: 16
                        font.family: "Ubuntu Sans"
                        elide: Text.ElideRight
                        visible: root.filterText.length > 0
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        text: "Search emoji…"
                        color: Theme.overlay1
                        font.pixelSize: 16
                        font.family: "Ubuntu Sans"
                        visible: root.filterText.length === 0
                    }

                    Rectangle {
                        visible: blinkCursor.cursorVisible
                        width: 2
                        height: 18
                        radius: 1
                        color: Theme.peach
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.min(filterTextItem.paintedWidth + 2, parent.width - 4)
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.surface0
            }

            // ── Emoji grid ─────────────────────────────────────────────────
            Item {
                width: parent.width
                height: card.gridTopSpacing + card.visibleGridHeight

                GridView {
                    id: grid
                    anchors.fill: parent
                    anchors.topMargin: card.gridTopSpacing
                    anchors.leftMargin: root.sidePadding
                    anchors.rightMargin: root.sidePadding
                    cellWidth: root.cellSize
                    cellHeight: root.cellSize
                    model: root.filteredEmojis
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: cell
                        required property int index
                        required property var modelData

                        width: root.cellSize
                        height: root.cellSize
                        color: root.selectedIndex === index
                            ? Config.alpha(Theme.peach, 0.15)
                            : (hoverMa.containsMouse ? Config.alpha(Theme.surface0, 0.5) : "transparent")
                        radius: 8
                        border.color: root.selectedIndex === index ? Theme.peach : "transparent"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: cell.modelData.glyph
                            font.pixelSize: 26
                            font.family: "Noto Color Emoji"
                        }

                        MouseArea {
                            id: hoverMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = cell.index
                            onClicked: root.commitEntry(cell.modelData)
                        }

                        // Tooltip with emoji name on hover
                        Rectangle {
                            visible: hoverMa.containsMouse
                            anchors.bottom: parent.top
                            anchors.bottomMargin: 4
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: nameText.implicitWidth + 16
                            height: 24
                            radius: 6
                            color: Theme.mantle
                            border.color: Theme.surface1
                            border.width: 1
                            z: 10

                            Text {
                                id: nameText
                                anchors.centerIn: parent
                                text: cell.modelData.name
                                color: Theme.text
                                font.pixelSize: 11
                                font.family: "Ubuntu Sans"
                            }
                        }
                    }
                }

                // Empty state
                Column {
                    anchors.centerIn: parent
                    visible: root.filteredEmojis.length === 0 && EmojiData.loaded
                    spacing: 6

                    Text {
                        text: "No matches"
                        color: Theme.overlay1
                        font.pixelSize: 13
                        font.family: "Ubuntu Sans"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    BlinkCursor {
        id: blinkCursor
        active: root.visible
    }

    onVisibleChanged: {
        if (visible) {
            filterText = ""
            buildFiltered()
            keyCatcher.forceActiveFocus()
        }
    }
}
