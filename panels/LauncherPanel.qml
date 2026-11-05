import QtQuick
import Quickshell
import "root:/"
import "root:/singletons"
import "root:/components"
import "root:/js/KeyNav.js" as KeyNav
import "root:/js/AppIcons.js" as AppIcons

// K1
PanelFrame {
    id: panel

    property string filterText: ""
    property int selectedIndex: 0
    property var filteredApps: []
    // The app whose desktop actions are listed instead of the search results
    property var actionsOf: null

    readonly property var rows: actionsOf ? actionsOf.actions : filteredApps
    readonly property int rowPitch: 50
    readonly property int visibleRows: 6

    panelWidth: Config.panelWideWidth
    bodyInset: 14
    bodyTopGap: 10
    spacing: 8

    function buildFiltered() {
        var query = filterText.trim().toLowerCase()
        var result = []
        var entries = Array.from(DesktopEntries.applications.values)
        // A game with a shortcut from Steam already has an entry
        var games = SteamData.games.filter(game => !entries.some(e => e.execString.trim().endsWith(game.execString)))
        var vals = entries.concat(games)
        for (var i = 0; i < vals.length; i++) {
            var e = vals[i]
            if (!e || !e.name || e.noDisplay) continue
            if (!query
                || e.name.toLowerCase().indexOf(query) >= 0
                || (e.genericName && e.genericName.toLowerCase().indexOf(query) >= 0)
                || (e.comment && e.comment.toLowerCase().indexOf(query) >= 0)) {
                result.push(e)
            }
        }
        result.sort(function(a, b) {
            if (query) {
                var aStarts = a.name.toLowerCase().startsWith(query)
                var bStarts = b.name.toLowerCase().startsWith(query)
                if (aStarts && !bStarts) return -1
                if (!aStarts && bStarts) return 1
            }
            var usageA = AppUsageData.usageOf(a.id)
            var usageB = AppUsageData.usageOf(b.id)
            if (usageA !== usageB) return usageB - usageA
            return a.name.localeCompare(b.name)
        })
        filteredApps = result
        selectedIndex = result.length > 0 ? 0 : -1
    }

    onFilterTextChanged: buildFiltered()
    Component.onCompleted: {
        buildFiltered()
        SteamData.refresh()
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { panel.buildFiltered() }
    }

    Connections {
        target: SteamData
        function onGamesChanged() { panel.buildFiltered() }
    }

    Connections {
        target: AppUsageData
        function onUsageLoadedChanged() { panel.buildFiltered() }
    }

    function launchRow(row) {
        if (!row) return
        if (actionsOf) {
            row.execute()
        } else {
            var cmd = row.execString.replace(/%[fFuUcCkdki%]/g, "").trim()
            if (!cmd) return
            AppUsageData.recordUsage(row.id)
            HyprlandData.exec(cmd)
        }
        AppState.closePanel()
    }

    function select(index) {
        selectedIndex = Math.max(0, Math.min(rows.length - 1, index))
        list.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function toggleActions() {
        if (actionsOf) {
            actionsOf = null
        } else {
            var row = filteredApps[selectedIndex]
            if (!row || !row.actions || row.actions.length === 0) return
            actionsOf = row
        }
        selectedIndex = 0
    }

    function handleKey(event) {
        if (KeyNav.isConfirm(event)) {
            launchRow(rows[selectedIndex])
        } else if (KeyNav.isPrev(event)) {
            select(selectedIndex - 1)
        } else if (KeyNav.isNext(event)) {
            select(selectedIndex + 1)
        } else if (event.key === Qt.Key_Tab) {
            toggleActions()
        } else if (KeyNav.isBackspace(event)) {
            if (actionsOf) toggleActions()
            else if (filterText.length > 0) filterText = filterText.slice(0, -1)
        } else if (KeyNav.isPrintableChar(event) && !actionsOf) {
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
            placeholder: panel.actionsOf ? panel.actionsOf.name + " actions" : "Search apps…"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        KeyChip {
            id: chip
            text: HotkeyData.keyFor("launcher-toggle", "Super Space")
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    ListView {
        id: list

        width: parent.width
        height: Math.max(48, Math.min(panel.rows.length, panel.visibleRows) * panel.rowPitch - 2)
        model: panel.rows
        spacing: 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            id: row

            required property int index
            required property var modelData

            readonly property bool selected: index === panel.selectedIndex
            readonly property var glyph: panel.actionsOf ? null : AppIcons.glyphForApp(modelData)

            width: list.width
            height: 48
            radius: Config.controlRadius
            color: selected ? Theme.surfaceHigh : "transparent"

            Rectangle {
                id: letter
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                radius: 8
                color: row.selected ? Theme.accent : Theme.surfaceHigh

                IslandLabel {
                    anchors.centerIn: parent
                    visible: !row.glyph
                    text: (row.modelData.name || "?").charAt(0).toUpperCase()
                    kind: "island"
                    color: row.selected ? Theme.textOnAccent : Theme.text
                }

                AppGlyph {
                    visible: !!row.glyph
                    text: row.glyph ? row.glyph.char : ""
                    font.family: row.glyph ? row.glyph.font : ""
                    font.pixelSize: 20
                    color: row.selected ? Theme.textOnAccent : Theme.text
                }
            }

            Column {
                anchors.left: letter.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 36
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                IslandLabel {
                    width: parent.width
                    text: row.modelData.name
                    kind: "island"
                }

                IslandLabel {
                    width: parent.width
                    visible: text !== ""
                    text: panel.actionsOf ? "" : (row.modelData.genericName || row.modelData.comment || "")
                    kind: "meta"
                }
            }

            IslandLabel {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                visible: row.selected
                text: "↵"
                kind: "meta"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: panel.selectedIndex = row.index
                onClicked: panel.launchRow(row.modelData)
            }
        }

        IslandLabel {
            anchors.centerIn: parent
            visible: panel.rows.length === 0
            text: "No matching apps"
            kind: "meta"
        }
    }

    HintRow {
        x: 8
        width: parent.width - 16
        hints: panel.actionsOf ? ["↵ run", "↑↓ move", "Tab back"] : ["↵ open", "↑↓ move", "Tab actions"]
    }
}
