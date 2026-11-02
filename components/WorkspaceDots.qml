import QtQuick
import Quickshell.Hyprland
import "root:/"

// One dot per workspace on this output: a pill for the active one, brighter
// dots where windows are open. Scrolling steps through them.
Row {
    id: root

    required property var screen
    property bool shrunk: false         // only active and occupied workspaces
    property bool muted: false          // unfocused output: no accent
    property int dotSize: 6
    property int activeWidth: 18
    property int cellHeight: Config.islandHeight

    readonly property var slots: Config.workspaceSlots(AppState.outputDescriptions[screen.name])

    function workspaceFor(id) {
        var list = Hyprland.workspaces.values
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) return list[i]
        }
        return null
    }

    function step(delta) {
        var current = 0
        for (var i = 0; i < slots.length; i++) {
            var ws = workspaceFor(slots[i])
            if (ws && ws.active) current = i
        }
        var next = Math.max(0, Math.min(slots.length - 1, current + delta))
        if (next !== current) Hyprland.dispatch("workspace " + slots[next])
    }

    Repeater {
        model: root.slots

        delegate: Item {
            id: cell

            required property var modelData

            readonly property var workspace: {
                var _values = Hyprland.workspaces.values
                return root.workspaceFor(modelData)
            }
            readonly property bool isActive: workspace !== null && workspace.active
            readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0

            visible: !root.shrunk || isActive || occupied
            width: dot.width + 5
            height: root.cellHeight

            Rectangle {
                id: dot
                anchors.centerIn: parent
                width: cell.isActive ? root.activeWidth : root.dotSize
                height: root.dotSize
                radius: height / 2
                color: {
                    if (cell.isActive) return root.muted ? Theme.textDim : Theme.accent
                    if (dotMouse.containsMouse) return Theme.text
                    return cell.occupied ? Theme.overlay2 : Theme.surfaceTop
                }

                Behavior on width {
                    NumberAnimation { duration: Config.widthChangeMs; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                    ColorAnimation { duration: Config.animationDuration }
                }
            }

            MouseArea {
                id: dotMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + cell.modelData)
                onWheel: wheel => root.step(wheel.angleDelta.y > 0 ? -1 : 1)
            }
        }
    }
}
