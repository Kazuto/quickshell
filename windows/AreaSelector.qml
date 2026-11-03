import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/components"
import "root:/singletons"

// Picks an area for a screenshot or recording, with yarn from the screen's corners to
// the pointer, or to the corners of the area once it's being dragged. A click without
// dragging picks the window under the pointer, or the whole screen if there is none.
PanelWindow {
    id: selector

    required property var modelData

    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    // grimblast's rule for slurp's overlay matches this name too
    WlrLayershell.namespace: "selection"
    WlrLayershell.layer: WlrLayer.Overlay
    // Hyprland only routes the pointer to exclusive surfaces while one is up
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    readonly property real screenX: modelData.x
    readonly property real screenY: modelData.y

    property bool pointerHere: false
    property real pointerX: 0
    property real pointerY: 0

    property bool dragging: false
    property real dragStartX: 0
    property real dragStartY: 0

    readonly property real areaLeft: Math.min(dragStartX, pointerX)
    readonly property real areaTop: Math.min(dragStartY, pointerY)
    readonly property real areaRight: Math.max(dragStartX, pointerX)
    readonly property real areaBottom: Math.max(dragStartY, pointerY)

    // Below this it's a click, not a drag
    readonly property real clickDistance: 4
    readonly property bool dragged: dragging
        && (areaRight - areaLeft >= clickDistance || areaBottom - areaTop >= clickDistance)

    // What a click would pick right now, in this screen's coordinates
    readonly property var clickTarget: {
        if (!pointerHere || dragged) return null

        var found = AreaSelectData.windowAt(screenX + pointerX, screenY + pointerY)
        return found
            ? { x: found.x - screenX, y: found.y - screenY, width: found.width, height: found.height }
            : { x: 0, y: 0, width: width, height: height }
    }

    function pointerMoved(x, y) {
        pointerHere = true
        pointerX = Math.max(0, Math.min(width, x))
        pointerY = Math.max(0, Math.min(height, y))
    }

    function finishAt(area) {
        AreaSelectData.finish(
            Math.round(screenX + area.x) + "," + Math.round(screenY + area.y) + " "
                + Math.round(area.width) + "x" + Math.round(area.height))
    }

    // The pointer may be sitting still on this screen, so no event says where it is
    Connections {
        target: AreaSelectData
        function onStartCursorChanged() {
            var cursor = AreaSelectData.startCursor
            if (!selector.pointerHere && cursor.x >= selector.screenX && cursor.x < selector.screenX + selector.width
                    && cursor.y >= selector.screenY && cursor.y < selector.screenY + selector.height)
                selector.pointerMoved(cursor.x - selector.screenX, cursor.y - selector.screenY)
        }
    }

    Item {
        anchors.fill: parent
        visible: !AreaSelectData.closing

        // Everything outside the area is dimmed
        Item {
            id: dim

            anchors.fill: parent

            readonly property color shade: Config.alpha(Theme.desk, 0.5)
            readonly property real cutLeft: selector.dragged ? selector.areaLeft : 0
            readonly property real cutTop: selector.dragged ? selector.areaTop : 0
            readonly property real cutRight: selector.dragged ? selector.areaRight : 0
            readonly property real cutBottom: selector.dragged ? selector.areaBottom : 0

            Rectangle { x: 0; y: 0; width: parent.width; height: dim.cutTop; color: dim.shade }
            Rectangle { x: 0; y: dim.cutBottom; width: parent.width; height: parent.height - dim.cutBottom; color: dim.shade }
            Rectangle { x: 0; y: dim.cutTop; width: dim.cutLeft; height: dim.cutBottom - dim.cutTop; color: dim.shade }
            Rectangle { x: dim.cutRight; y: dim.cutTop; width: parent.width - dim.cutRight; height: dim.cutBottom - dim.cutTop; color: dim.shade }
        }

        // Outline of the dragged area, or of what a click would pick
        Rectangle {
            readonly property var target: selector.dragged
                ? { x: selector.areaLeft, y: selector.areaTop, width: selector.areaRight - selector.areaLeft, height: selector.areaBottom - selector.areaTop }
                : selector.clickTarget

            visible: target !== null
            x: target ? target.x : 0
            y: target ? target.y : 0
            width: target ? target.width : 0
            height: target ? target.height : 0
            color: selector.dragged ? "transparent" : Config.alpha(Theme.accent, 0.08)
            border.color: Theme.accent
            border.width: 2
        }

        Repeater {
            model: [
                { x: 0, y: 0, right: false, bottom: false },
                { x: selector.width, y: 0, right: true, bottom: false },
                { x: 0, y: selector.height, right: false, bottom: true },
                { x: selector.width, y: selector.height, right: true, bottom: true }
            ]

            Item {
                id: yarnEnd

                required property var modelData
                required property int index

                anchors.fill: parent
                visible: selector.pointerHere

                YarnStrand {
                    id: strand

                    anchors.fill: parent
                    visible: yarnEnd.visible
                    phase: yarnEnd.index * 1.7
                    reach: Math.sqrt(selector.width * selector.width + selector.height * selector.height)
                    fixedEnd: Qt.point(yarnEnd.modelData.x, yarnEnd.modelData.y)
                    movingEnd: selector.dragged
                        ? Qt.point(yarnEnd.modelData.right ? selector.areaRight : selector.areaLeft,
                                   yarnEnd.modelData.bottom ? selector.areaBottom : selector.areaTop)
                        : Qt.point(selector.pointerX, selector.pointerY)
                }

                // A ball at the pointer, shrinking to a knot on each corner of the area
                YarnBall {
                    x: strand.p3.x - width / 2
                    y: strand.p3.y - height / 2
                    scale: selector.dragged ? 0.55 : 1

                    Behavior on scale {
                        NumberAnimation { duration: 120 }
                    }
                }
            }
        }

        // Size of the area, just inside the screen
        Rectangle {
            visible: selector.dragged
            x: Math.min(selector.areaRight + 10, selector.width - width - 10)
            y: Math.min(selector.areaBottom + 10, selector.height - height - 10)
            width: sizeLabel.implicitWidth + 16
            height: sizeLabel.implicitHeight + 8
            radius: height / 2
            color: Theme.island

            IslandLabel {
                id: sizeLabel
                anchors.centerIn: parent
                kind: "meta"
                text: Math.round(selector.areaRight - selector.areaLeft) + " × " + Math.round(selector.areaBottom - selector.areaTop)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.CrossCursor

        onPositionChanged: mouse => selector.pointerMoved(mouse.x, mouse.y)
        onExited: {
            if (!selector.dragging) selector.pointerHere = false
        }
        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                AreaSelectData.cancel()
                return
            }
            selector.pointerMoved(mouse.x, mouse.y)
            selector.dragStartX = selector.pointerX
            selector.dragStartY = selector.pointerY
            selector.dragging = true
        }
        onReleased: mouse => {
            if (mouse.button !== Qt.LeftButton || !selector.dragging) return

            if (selector.dragged) {
                selector.finishAt({
                    x: selector.areaLeft,
                    y: selector.areaTop,
                    width: selector.areaRight - selector.areaLeft,
                    height: selector.areaBottom - selector.areaTop
                })
            } else {
                selector.finishAt(selector.clickTarget)
            }
            selector.dragging = false
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: AreaSelectData.cancel()
        Component.onCompleted: forceActiveFocus()
    }
}
