pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/"

// Runs the area selector in windows/AreaSelector.qml and hands back what was picked as
// "x,y wxh" in global coordinates, or "" if it was cancelled.
Singleton {
    id: root

    property bool active: false
    // The overlay has blanked itself and is waiting for that to reach the screen
    property bool closing: false

    // What a click without dragging picks, topmost first: [{ x, y, width, height }]
    property var visibleWindows: []
    property point startCursor: Qt.point(-1, -1)

    property var pendingCallback: null
    property string pendingResult: ""

    function pick(callback) {
        if (pendingCallback) pendingCallback("")

        deliverDelay.stop()
        closing = false
        pendingCallback = callback
        visibleWindows = []
        AppState.closePanel()
        snapshotProcess.running = true
        // Same as grimblast, so the overlay can't fade out into a capture
        Quickshell.execDetached(["sh", "-c", HyprlandData.selectionRuleCommand])
        active = true
    }

    function finish(geometry) {
        if (!active || closing) return

        closing = true
        pendingResult = geometry
        deliverDelay.restart()
    }

    function cancel() {
        finish("")
    }

    function windowAt(x, y) {
        for (var i = 0; i < visibleWindows.length; i++) {
            var candidate = visibleWindows[i]
            if (x >= candidate.x && x < candidate.x + candidate.width
                    && y >= candidate.y && y < candidate.y + candidate.height)
                return candidate
        }
        return null
    }

    // Hyprland keeps a closing layer on screen for a moment, which a capture would catch.
    // Blanking it first and closing it a few frames later means nothing is left to catch.
    Timer {
        id: deliverDelay
        interval: 120
        onTriggered: {
            root.active = false
            root.closing = false

            var callback = root.pendingCallback
            root.pendingCallback = null
            if (callback) callback(root.pendingResult)
        }
    }

    // Hyprland only tells a new surface about the pointer once it moves, so a press
    // right away would go nowhere. Moving it to where it already is has the same effect.
    Timer {
        id: pointerNudge
        interval: 120
        onTriggered: {
            if (root.active)
                HyprlandData.moveCursor(root.startCursor.x, root.startCursor.y)
        }
    }

    Process {
        id: snapshotProcess
        command: ["sh", "-c", 'printf \'{"cursor":%s,"clients":%s,"monitors":%s}\' "$(hyprctl -j cursorpos)" "$(hyprctl -j clients)" "$(hyprctl -j monitors)"']
        stdout: StdioCollector {
            onStreamFinished: {
                var snapshot
                try {
                    snapshot = JSON.parse(this.text)
                } catch (e) {
                    return
                }

                var workspaces = []
                snapshot.monitors.forEach(monitor => {
                    workspaces.push(monitor.activeWorkspace.id)
                    if (monitor.specialWorkspace && monitor.specialWorkspace.id)
                        workspaces.push(monitor.specialWorkspace.id)
                })

                root.startCursor = Qt.point(snapshot.cursor.x, snapshot.cursor.y)
                pointerNudge.restart()
                root.visibleWindows = snapshot.clients
                    .filter(client => client.mapped && !client.hidden && workspaces.indexOf(client.workspace.id) >= 0)
                    .sort((a, b) => (b.floating - a.floating) || (a.focusHistoryID - b.focusHistoryID))
                    .map(client => ({ x: client.at[0], y: client.at[1], width: client.size[0], height: client.size[1] }))
            }
        }
    }
}
