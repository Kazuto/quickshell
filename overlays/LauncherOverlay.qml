import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "root:/"
import "root:/singletons"
import "root:/components"
import "root:/js/KeyNav.js" as KeyNav

PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // ── State ──────────────────────────────────────────────────────────────
    property string filterText: ""
    property int selectedIndex: 0
    property var filteredApps: []

    // ── Build filtered list from DesktopEntries singleton ──────────────────
    function buildFiltered() {
        var query = filterText.trim().toLowerCase()
        var result = []
        var apps = DesktopEntries.applications
        var vals = apps.values
        var count = apps.rowCount()
        for (var i = 0; i < count; i++) {
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

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root.buildFiltered() }
    }

    Connections {
        target: AppUsageData
        function onUsageLoadedChanged() { root.buildFiltered() }
    }

    // ── Launch ─────────────────────────────────────────────────────────────
    function launch(entry) {
        if (!entry) return
        var cmd = entry.execString.replace(/%[fFuUcCkdki%]/g, "").trim()
        if (!cmd) return
        AppUsageData.recordUsage(entry.id)
        Qt.createQmlObject(
            'import Quickshell.Io; Process { command: ["hyprctl", "dispatch", "exec", ' + JSON.stringify(cmd) + ']; running: true }',
            root
        )
        closeOverlay()
    }

    function launchSelected() {
        if (selectedIndex >= 0 && selectedIndex < filteredApps.length)
            launch(filteredApps[selectedIndex])
    }

    function closeOverlay() {
        filterText = ""
        AppState.launcherOverlayVisible = false
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
                root.launchSelected()
                event.accepted = true

                return
            }

            if (KeyNav.isPrev(event)) {
                if (root.selectedIndex > 0) {
                    root.selectedIndex--
                    resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                }
                event.accepted = true

                return
            }

            if (KeyNav.isNext(event)) {
                if (root.selectedIndex < root.filteredApps.length - 1) {
                    root.selectedIndex++
                    resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                }
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
        width: 560
        anchors.horizontalCenter: parent.horizontalCenter

        // Pin the top edge to where verticalCenter would be at max height,
        // so the card only grows downward and never jumps.
        property int rowHeight: 52
        property int maxRows: 10
        property int maxHeight: searchRow.height + 1 + maxRows * rowHeight
        anchors.top: parent.top
        anchors.topMargin: Math.round((parent.height - maxHeight) / 2)

        height: searchRow.height
                + (filteredApps.length > 0 ? 1 : 0)   // divider
                + Math.min(filteredApps.length, maxRows) * rowHeight

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
                leftPadding: 18
                rightPadding: 18
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: " "
                    color: Theme.subtext0
                    font.pixelSize: 16
                    font.family: Config.moduleFontFamily
                }

                Item {
                    width: parent.width - 56
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        text: root.filterText
                        color: Theme.text
                        font.pixelSize: 16
                        font.family: Config.moduleFontFamily
                        elide: Text.ElideRight
                        visible: root.filterText.length > 0
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        text: "Search apps…"
                        color: Theme.overlay1
                        font.pixelSize: 16
                        font.family: Config.moduleFontFamily
                        visible: root.filterText.length === 0
                    }

                    // Blinking cursor
                    Rectangle {
                        visible: blinkCursor.cursorVisible
                        width: 2
                        height: 18
                        radius: 1
                        color: Theme.peach
                        anchors.verticalCenter: parent.verticalCenter
                        x: {
                            // approximate: 9.6px per character at 16px font
                            var charW = 9.6
                            return Math.min(root.filterText.length * charW, parent.width - 4)
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.surface0
                visible: filteredApps.length > 0
            }

            // ── Results list ───────────────────────────────────────────────
            ListView {
                id: resultList
                width: parent.width
                height: Math.min(root.filteredApps.length, card.maxRows) * card.rowHeight
                model: root.filteredApps
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: appRow
                    required property int index
                    required property var modelData

                    width: resultList.width
                    height: card.rowHeight
                    color: root.selectedIndex === index
                        ? Config.alpha(Theme.peach, 0.12)
                        : (hoverMa.containsMouse ? Config.alpha(Theme.surface0, 0.5) : "transparent")

                    // Left accent bar
                    Rectangle {
                        visible: root.selectedIndex === appRow.index
                        width: 3
                        height: 28
                        radius: 2
                        color: Theme.peach
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        anchors {
                            left: parent.left
                            leftMargin: 20
                            right: parent.right
                            rightMargin: 18
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 12

                        // App icon
                        Image {
                            id: appIcon
                            width: 26
                            height: 26
                            anchors.verticalCenter: parent.verticalCenter
                            source: appRow.modelData.icon
                                ? ("image://icon/" + appRow.modelData.icon)
                                : ""
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: 52
                            sourceSize.height: 52
                            asynchronous: true

                            Text {
                                visible: appIcon.status !== Image.Ready
                                anchors.centerIn: parent
                                text: "󰘔"
                                color: Theme.subtext0
                                font.pixelSize: 18
                                font.family: Config.moduleFontFamily
                            }
                        }

                        // Name + subtext
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width - 38

                            Text {
                                width: parent.width
                                text: appRow.modelData.name
                                color: root.selectedIndex === appRow.index ? Theme.peach : Theme.text
                                font.pixelSize: 13
                                font.family: Config.moduleFontFamily
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: appRow.modelData.genericName || appRow.modelData.comment || ""
                                color: Theme.subtext0
                                font.pixelSize: 11
                                font.family: Config.moduleFontFamily
                                elide: Text.ElideRight
                                visible: text.length > 0
                            }
                        }
                    }

                    MouseArea {
                        id: hoverMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selectedIndex = appRow.index
                        onClicked: root.launch(appRow.modelData)
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
