import QtQuick
import Qt5Compat.GraphicalEffects
import "root:/"

// Generic coverflow-style carousel: a large centered item flanked by
// smaller, dimmed peeking items on either side, wrapping infinitely in
// both directions. Used by picker overlays (wallpapers today, themes
// later) that want a "pick one visually" UI instead of a searchable
// list/grid.
//
// Usage:
//   Carousel {
//       model: [{ thumb: "file:///path/to/a.jpg", label: "a", isCurrent: true }, ...]
//       currentIndex: 0
//       onItemActivated: function(index) { ... apply model[index] ... }
//   }
Item {
    id: root

    // Each entry: { thumb: <image source url>, label: <string>, isCurrent: <bool> }
    property var model: []
    property int currentIndex: 0

    property int itemWidth: 300
    property int itemHeight: 170
    property int cornerRadius: 16
    // Per-step scale/opacity falloff for items away from center (applied as
    // falloff^|distance|, so it fades smoothly rather than in two flat tiers).
    property real scaleFalloff: 0.82
    property real opacityFalloff: 0.6
    property int maxVisibleDistance: 3
    // Horizontal distance between item centers, as a fraction of itemWidth.
    // < 1.0 makes neighbors peek out from behind the centered item.
    property real stepFactor: 0.62

    readonly property int count: model.length

    signal itemActivated(int index)

    // Shortest signed distance from currentIndex to index, wrapping around
    // the ends of the model — e.g. with 14 items, item 0 is distance +1
    // from item 13, not +13, so neighbors peek on both sides everywhere.
    function wrappedDistance(index) {
        if (root.count === 0) return 0
        var raw = index - root.currentIndex
        var half = root.count / 2
        raw = ((raw % root.count) + root.count) % root.count
        if (raw > half) raw -= root.count
        return raw
    }

    function next() {
        if (count === 0) return
        currentIndex = (currentIndex + 1) % count
    }

    function prev() {
        if (count === 0) return
        currentIndex = (currentIndex - 1 + count) % count
    }

    function activateCurrent() {
        if (currentIndex >= 0 && currentIndex < count) itemActivated(currentIndex)
    }

    function scaleForDistance(distance) {
        return Math.pow(root.scaleFalloff, Math.abs(distance))
    }

    function opacityForDistance(distance) {
        if (Math.abs(distance) > root.maxVisibleDistance) return 0.0
        return Math.pow(root.opacityFalloff, Math.abs(distance))
    }

    implicitWidth: itemWidth * 2.4
    implicitHeight: itemHeight

    // ── Stage ──────────────────────────────────────────────────────────────
    Item {
        id: stage
        anchors.fill: parent

        Repeater {
            model: root.model

            delegate: Item {
                id: cell
                required property int index
                required property var modelData

                readonly property int distance: root.wrappedDistance(index)
                readonly property real targetScale: root.scaleForDistance(distance)
                readonly property real cellOpacity: root.opacityForDistance(distance)
                readonly property bool isCenter: distance === 0

                width: root.itemWidth
                height: root.itemHeight
                scale: cell.targetScale
                opacity: cell.cellOpacity
                visible: cell.cellOpacity > 0.02
                z: isCenter ? 10 : (10 - Math.abs(distance))

                x: stage.width / 2 - width / 2
                    + distance * root.itemWidth * root.stepFactor
                y: (stage.height - height) / 2

                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                // Background fill, visible only where the (rounded) mask
                // doesn't cover — i.e. it's just a fallback behind the image.
                Rectangle {
                    anchors.fill: parent
                    radius: root.cornerRadius
                    color: Theme.surface0
                }

                // The thumbnail, masked to the same rounded shape as the
                // frame below. Plain `clip: true` on a Rectangle only clips
                // to its bounding box, not its rounded corners, so a
                // full-bleed Image would otherwise paint square corners
                // right over the rounded background.
                Image {
                    id: thumbImage
                    anchors.fill: parent
                    source: cell.modelData.thumb || ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                    sourceSize.width: width * Screen.devicePixelRatio
                    sourceSize.height: height * Screen.devicePixelRatio
                }

                Rectangle {
                    id: maskShape
                    anchors.fill: parent
                    radius: root.cornerRadius
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: thumbImage
                    maskSource: maskShape
                }

                // Border drawn as its own transparent-filled rectangle *on
                // top* of the masked image — a border on the background
                // Rectangle above would otherwise be painted over by the
                // full-bleed image before this point.
                Rectangle {
                    anchors.fill: parent
                    radius: root.cornerRadius
                    color: "transparent"
                    border.color: cell.isCenter ? Theme.peach : Theme.surface1
                    border.width: cell.isCenter ? 3 : 1
                }

                // Checkmark badge for whichever item is the actually
                // applied one (may differ from the centered/previewed one).
                Rectangle {
                    visible: !!cell.modelData.isCurrent
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: 8
                    }
                    width: 22
                    height: 22
                    radius: 11
                    color: Config.alpha(Theme.peach, 0.9)

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00c"
                        color: Theme.base
                        font.pixelSize: 11
                        font.family: Config.moduleFontFamily
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (cell.isCenter) root.itemActivated(cell.index)
                        else root.currentIndex = cell.index
                    }
                }
            }
        }
    }

    // ── Chevron navigation ───────────────────────────────────────────────
    Rectangle {
        id: prevButton
        visible: root.count > 1
        anchors {
            left: parent.left
            verticalCenter: stage.verticalCenter
        }
        width: 36
        height: 36
        radius: 18
        color: prevMa.containsMouse ? Config.alpha(Theme.surface1, 0.9) : Config.alpha(Theme.surface0, 0.7)

        Text {
            anchors.centerIn: parent
            text: "\uf053"
            color: Theme.text
            font.pixelSize: 14
            font.family: Config.moduleFontFamily
        }

        MouseArea {
            id: prevMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.prev()
        }
    }

    Rectangle {
        id: nextButton
        visible: root.count > 1
        anchors {
            right: parent.right
            verticalCenter: stage.verticalCenter
        }
        width: 36
        height: 36
        radius: 18
        color: nextMa.containsMouse ? Config.alpha(Theme.surface1, 0.9) : Config.alpha(Theme.surface0, 0.7)

        Text {
            anchors.centerIn: parent
            text: "\uf054"
            color: Theme.text
            font.pixelSize: 14
            font.family: Config.moduleFontFamily
        }

        MouseArea {
            id: nextMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.next()
        }
    }
}
