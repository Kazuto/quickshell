import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"
import "root:/js/KeyNav.js" as KeyNav

// Opened from quick access. Not in the design; follows the launcher's layout.
PanelFrame {
    id: panel

    property string filterText: ""
    property int selectedIndex: 0

    readonly property var rows: {
        var query = filterText.toLowerCase()
        return ClipboardData.entries.filter(function(entry) {
            return !query || entry.preview.toLowerCase().indexOf(query) >= 0
        })
    }

    panelWidth: Config.panelWideWidth
    bodyInset: 14
    bodyTopGap: 10
    spacing: 8

    Component.onCompleted: ClipboardData.refresh()
    onFilterTextChanged: selectedIndex = 0

    function restore(entry) {
        if (!entry) return
        ClipboardData.restore(entry.id)
        AppState.closePanel()
    }

    function select(index) {
        selectedIndex = Math.max(0, Math.min(rows.length - 1, index))
        list.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function handleKey(event) {
        if (KeyNav.isConfirm(event)) {
            restore(rows[selectedIndex])
        } else if (KeyNav.isPrev(event)) {
            select(selectedIndex - 1)
        } else if (KeyNav.isNext(event)) {
            select(selectedIndex + 1)
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
            width: panel.headerWidth
            text: panel.filterText
            placeholder: "Search clipboard…"
            iconName: "clipboard"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    ListView {
        id: list

        width: parent.width
        height: Math.max(48, Math.min(panel.rows.length, 8) * 38 - 2)
        model: panel.rows
        spacing: 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            id: row

            required property int index
            required property var modelData

            width: list.width
            height: 36
            radius: Config.controlRadius
            color: index === panel.selectedIndex ? Theme.surfaceHigh : "transparent"

            IslandLabel {
                x: 12
                width: parent.width - 24
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.preview
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: panel.selectedIndex = row.index
                onClicked: panel.restore(row.modelData)
            }
        }

        IslandLabel {
            anchors.centerIn: parent
            visible: panel.rows.length === 0
            text: "Clipboard history is empty"
            kind: "meta"
        }
    }

    HintRow {
        x: 8
        width: parent.width - 16
        hints: ["↵ copy", "↑↓ move"]
    }
}
