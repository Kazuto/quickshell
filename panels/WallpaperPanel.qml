import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"
import "root:/js/KeyNav.js" as KeyNav

// K5: the full-width variant, a strip of five around the current pick
PanelFrame {
    id: panel

    required property string outputName

    property int currentIndex: 0
    property int applyScope: 0   // 0 = all outputs, 1 = this output
    property bool hasSynced: false

    readonly property var wallpapers: WallpaperData.wallpapers
    readonly property var selected: wallpapers.length > 0 ? wallpapers[currentIndex] : null
    readonly property string directoryLabel: "~/Wallpaper"

    panelWidth: Config.panelFullWidth

    Component.onCompleted: WallpaperData.refresh()

    // Lands on the wallpaper in use as soon as the progressively loading list has it
    onWallpapersChanged: {
        if (hasSynced) return
        for (var i = 0; i < wallpapers.length; i++) {
            if (wallpapers[i].path === WallpaperData.current) {
                currentIndex = i
                hasSynced = true
                return
            }
        }
    }

    onSelectedChanged: WallpaperData.identify(selected ? selected.path : "")

    function wrapped(offset) {
        var n = wallpapers.length
        return n > 0 ? wallpapers[((currentIndex + offset) % n + n) % n] : null
    }

    function browse(delta) {
        var n = wallpapers.length
        if (n > 0) currentIndex = ((currentIndex + delta) % n + n) % n
    }

    function applyCurrent() {
        if (!selected) return
        WallpaperData.apply(selected.path, applyScope === 1 ? outputName : "")
        AppState.closePanel()
    }

    function handleKey(event) {
        if (KeyNav.isConfirm(event)) applyCurrent()
        else if (KeyNav.isPrevColumn(event)) browse(-1)
        else if (KeyNav.isNextColumn(event)) browse(1)
        else return
        event.accepted = true
    }

    headerLeft: [
        SvgIcon {
            name: "image"
            size: 16
            color: Theme.text
            anchors.verticalCenter: parent.verticalCenter
        },
        IslandLabel {
            text: "Wallpaper"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        },
        IslandLabel {
            text: panel.wallpapers.length + " in " + panel.directoryLabel
            kind: "meta"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        KeyChip {
            text: HotkeyData.keyFor("wallpaper-toggle", "Super ,")
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    Item {
        width: parent.width
        height: 198

        IslandButton {
            x: 2
            anchors.verticalCenter: parent.verticalCenter
            iconName: "caret-left"
            iconSize: 12
            onClicked: panel.browse(-1)
        }

        IslandButton {
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            iconName: "caret-right"
            iconSize: 12
            onClicked: panel.browse(1)
        }

        Row {
            anchors.centerIn: parent
            spacing: 16

            Repeater {
                model: [-2, -1, 0, 1, 2]

                delegate: Rectangle {
                    id: thumb

                    required property var modelData

                    readonly property bool isCenter: modelData === 0
                    readonly property var wallpaper: panel.wrapped(modelData)

                    width: isCenter ? 352 : 176
                    height: isCenter ? 198 : 100
                    radius: Config.controlRadius
                    color: Theme.surfaceHigh
                    anchors.verticalCenter: parent.verticalCenter

                    RoundedImage {
                        anchors.fill: parent
                        radius: parent.radius
                        source: thumb.wallpaper ? "file://" + thumb.wallpaper.thumb : ""
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (thumb.isCenter) panel.applyCurrent()
                            else panel.browse(thumb.modelData)
                        }
                    }
                }
            }
        }

        IslandLabel {
            anchors.centerIn: parent
            visible: WallpaperData.loaded && panel.wallpapers.length === 0
            text: "No wallpapers found"
            kind: "meta"
        }
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 352
        height: 14

        IslandLabel {
            width: parent.width - dimensions.implicitWidth - 12
            anchors.verticalCenter: parent.verticalCenter
            text: panel.selected ? panel.selected.name : ""
            kind: "island"
            font.pixelSize: 11
        }

        IslandLabel {
            id: dimensions
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: WallpaperData.selectedDimensions
            kind: "meta"
        }
    }

    Item {
        width: parent.width
        height: 36

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16

            IslandLabel {
                text: "Apply to"
                kind: "meta"
                anchors.verticalCenter: parent.verticalCenter
            }

            SegmentedControl {
                width: 210
                implicitHeight: 36
                options: ["All outputs", panel.outputName + " only"]
                currentIndex: panel.applyScope
                anchors.verticalCenter: parent.verticalCenter
                onActivated: index => panel.applyScope = index
            }

            CheckBox {
                checked: WallpaperData.deriveAccent
                anchors.verticalCenter: parent.verticalCenter
                onToggled: WallpaperData.setDeriveAccent(!WallpaperData.deriveAccent)
            }

            IslandLabel {
                text: "Derive accent from wallpaper"
                kind: "meta"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16

            IslandLabel { text: "↵ apply"; kind: "meta" }
            IslandLabel { text: "←→ browse"; kind: "meta" }
            IslandLabel { text: "Esc close"; kind: "meta" }
        }
    }
}
