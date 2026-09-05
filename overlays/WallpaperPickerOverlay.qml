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

    // ── Model for the Carousel — plain {thumb,label,isCurrent} objects ────
    property var carouselModel: []
    property bool hasSyncedToCurrent: false

    function rebuildModel() {
        var list = WallpaperData.wallpapers
        var result = []
        for (var i = 0; i < list.length; i++) {
            var w = list[i]
            result.push({
                thumb: "file://" + w.thumb,
                label: w.name,
                isCurrent: WallpaperData.current === w.path,
                path: w.path
            })
        }
        carouselModel = result

        if (!hasSyncedToCurrent && result.length > 0) {
            hasSyncedToCurrent = true
            var idx = -1
            for (var j = 0; j < result.length; j++) {
                if (result[j].isCurrent) { idx = j; break }
            }
            carousel.currentIndex = idx >= 0 ? idx : 0
        }
    }

    Connections {
        target: WallpaperData
        function onWallpapersChanged() { root.rebuildModel() }
    }

    function applyCurrent() {
        if (carousel.currentIndex < 0 || carousel.currentIndex >= carouselModel.length) return
        WallpaperData.apply(carouselModel[carousel.currentIndex].path)
        closeOverlay()
    }

    function closeOverlay() {
        AppState.wallpaperPickerOverlayVisible = false
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
                root.applyCurrent()
                event.accepted = true

                return
            }

            if (KeyNav.isPrevColumn(event)) {
                carousel.prev()
                event.accepted = true

                return
            }

            if (KeyNav.isNextColumn(event)) {
                carousel.next()
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

    // ── Carousel + hint, floating directly on the scrim (no boxed card) ────
    Column {
        anchors.centerIn: parent
        spacing: 16

        Carousel {
            id: carousel
            anchors.horizontalCenter: parent.horizontalCenter
            width: implicitWidth
            model: root.carouselModel
            itemHeight: root.height * 0.5
            itemWidth: itemHeight * (16 / 9)
            onItemActivated: function(index) { root.applyCurrent() }
        }

        Text {
            id: hintText
            anchors.horizontalCenter: parent.horizontalCenter
            text: WallpaperData.loaded && root.carouselModel.length === 0
                ? "No wallpapers found"
                : "Enter to apply  ·  ←/→ to browse  ·  Esc to close"
            color: Theme.overlay1
            font.pixelSize: 12
            font.family: Config.moduleFontFamily
        }
    }

    onVisibleChanged: {
        if (visible) {
            hasSyncedToCurrent = false
            WallpaperData.refresh()
            rebuildModel()
            keyCatcher.forceActiveFocus()
        }
    }
}
