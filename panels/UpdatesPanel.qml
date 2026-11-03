import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

// What could be updated. Packages install together in a terminal. Firmware goes one device
// at a time, because it needs a restart and a BIOS update can't always be rolled back.
PanelFrame {
    id: panel

    property string filter: "all"

    readonly property var sourceLabels: ({
        apt: "Apt", pacman: "Pacman", aur: "AUR", snap: "Snap", flatpak: "Flatpak", firmware: "Firmware"
    })
    readonly property var filters: {
        var result = [{ id: "all", label: "All", count: UpdateData.updates.length }]
        Object.keys(sourceLabels).forEach(source => {
            var count = UpdateData.updates.filter(update => update.source === source).length
            if (count > 0) result.push({ id: source, label: sourceLabels[source], count: count })
        })
        return result
    }
    // A source disappears from the chips once it has nothing left to update
    readonly property string activeFilter: filters.some(entry => entry.id === filter) ? filter : "all"
    readonly property var shown: activeFilter === "all"
        ? UpdateData.updates
        : UpdateData.updates.filter(update => update.source === activeFilter)

    backTo: "control"
    spacing: 12

    Component.onCompleted: UpdateData.check()

    function handleKey(event) {
        if (event.key !== Qt.Key_Tab) return
        var current = filters.findIndex(entry => entry.id === activeFilter)
        filter = filters[(current + 1) % filters.length].id
        event.accepted = true
    }

    headerLeft: [
        SvgIcon {
            name: "update"
            size: 16
            color: Theme.text
            anchors.verticalCenter: parent.verticalCenter
        },
        IslandLabel {
            text: "Updates"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        IslandLabel {
            visible: UpdateData.checking
            text: "Checking…"
            kind: "meta"
            anchors.verticalCenter: parent.verticalCenter
        },
        IslandButton {
            implicitHeight: 28
            iconName: "refresh"
            iconSize: 12
            active: !UpdateData.checking
            anchors.verticalCenter: parent.verticalCenter
            onClicked: UpdateData.check()
        }
    ]

    Repeater {
        model: UpdateData.warnings

        delegate: IslandLabel {
            required property string modelData

            width: parent.width
            maximumLineCount: 3
            wrapMode: Text.Wrap
            text: modelData
            kind: "meta"
            color: Theme.warn
        }
    }

    Rectangle {
        visible: UpdateData.restartNeeded
        width: parent.width
        height: 40
        radius: 20
        color: restartMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceLow

        IslandLabel {
            x: 16
            width: parent.width - 2 * x
            anchors.verticalCenter: parent.verticalCenter
            text: UpdateData.restartReason !== ""
                ? "Restart to finish updating " + UpdateData.restartReason
                : "Restart to finish updating"
            color: Theme.accent
        }

        MouseArea {
            id: restartMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: AppState.openPanel("system")
        }
    }

    Flow {
        visible: UpdateData.updates.length > 0
        width: parent.width
        spacing: 6

        Repeater {
            model: panel.filters

            // Slimmer than usual, since up to six sources share the row
            delegate: FilterChip {
                required property var modelData

                width: implicitWidth - 6
                label: modelData.label + " " + modelData.count
                selected: panel.activeFilter === modelData.id
                onClicked: panel.filter = modelData.id
            }
        }
    }

    Flickable {
        visible: panel.shown.length > 0
        width: parent.width
        height: Math.min(rows.implicitHeight, 320)
        contentHeight: rows.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: rows
            width: parent.width

            Repeater {
                model: panel.shown

                delegate: Item {
                    id: updateRow

                    required property var modelData

                    readonly property bool foreign: modelData.note.startsWith("from ")

                    width: rows.width
                    height: 42

                    Column {
                        anchors.left: parent.left
                        anchors.right: rowEnd.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        IslandLabel {
                            width: parent.width
                            text: updateRow.modelData.name
                        }

                        // The note goes first, so a long version gets cut off instead of it
                        IslandLabel {
                            width: parent.width
                            text: updateRow.modelData.note !== ""
                                ? updateRow.modelData.note + " · " + updateRow.modelData.version
                                : updateRow.modelData.version
                            kind: "meta"
                            color: updateRow.foreign ? Theme.warn
                                : updateRow.modelData.note === "security" ? Theme.accent
                                : Theme.textDim
                        }
                    }

                    Row {
                        id: rowEnd
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        IslandLabel {
                            visible: panel.activeFilter === "all" && updateRow.modelData.source !== "firmware"
                            text: panel.sourceLabels[updateRow.modelData.source] || ""
                            kind: "meta"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        IslandButton {
                            visible: updateRow.modelData.source === "firmware"
                            implicitHeight: 28
                            label: "Update"
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: {
                                UpdateData.installFirmware(updateRow.modelData.id)
                                AppState.closePanel()
                            }
                        }
                    }
                }
            }
        }
    }

    IslandLabel {
        visible: UpdateData.updates.length === 0
        width: parent.width
        height: 72
        horizontalAlignment: Text.AlignHCenter
        text: UpdateData.checking || UpdateData.checkedAt === 0 ? "Checking…"
            : UpdateData.warnings.length > 0 ? "No updates found"
            : "Everything is up to date"
        kind: "meta"
    }

    Item {
        visible: UpdateData.packageCount > 0
        width: parent.width
        height: 32

        IslandButton {
            anchors.right: parent.right
            implicitHeight: 32
            // Not the usual call to action while something about the sources looks wrong
            variant: UpdateData.warnings.length > 0 ? "raised" : "accent"
            label: "Update " + UpdateData.packageCount + (UpdateData.packageCount === 1 ? " package" : " packages")
            onClicked: {
                UpdateData.installPackages()
                AppState.closePanel()
            }
        }
    }
}
