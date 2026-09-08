import QtQuick
import Quickshell
import Quickshell.Hyprland
import "root:/"
import "root:/js/AppIcons.js" as AppIcons

Rectangle {
    id: root

    property int startWorkspace: 1  // Starting workspace number
    property string defaultIcon: ""  // If set, use this icon for all workspaces

    implicitWidth: workspaceRow.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: Config.moduleBackground
    radius: Config.moduleRadius

    // Normalizes both the "defaultIcon" (plain Nerd Font glyph string, used
    // by the secondary/tertiary bars) and AppIcons.js glyph lookups into the
    // same {char, font, offsetX} shape so the delegate below doesn't need
    // to care which source a given workspace's icon came from.
    function plainGlyph(glyphChar) {
        return { char: glyphChar, font: null, offsetX: 0 }
    }

    // Falls back to the running app's own first letter when it has no
    // curated AppIcons.js entry, so an unmapped app still shows *something*
    // distinct rather than making the workspace look icon-less.
    function glyphForClass(cls) {
        return AppIcons.glyphFor(cls) || plainGlyph((cls || "?").charAt(0).toUpperCase())
    }

    // Distinct running app classes currently on this workspace, in the
    // order they first appear in Hyprland's toplevel list. Two windows of
    // the same app (e.g. two Ghostty windows) collapse to one icon; a
    // workspace running Chrome *and* Vivaldi shows both.
    function windowClassesForWorkspace(workspaceNum) {
        var seen = {}
        var result = []
        var list = Hyprland.toplevels.values
        for (var i = 0; i < list.length; i++) {
            var ipc = list[i].lastIpcObject
            if (!ipc || !ipc.workspace || ipc.workspace.id !== workspaceNum) continue
            var cls = ipc.class || ""
            if (!cls || seen[cls]) continue
            seen[cls] = true
            result.push(cls)
        }
        return result
    }

    // Explicit refresh trigger — incremented whenever a window opens,
    // closes, or moves workspace. Each workspace cell's windowClasses
    // depends on this counter (rather than relying on Hyprland.toplevels'
    // own change notifications directly), because a *newly opened*
    // window's lastIpcObject isn't populated yet at the exact moment
    // Hyprland.toplevels.valuesChanged first fires — even an explicit
    // Hyprland.refreshToplevels() call doesn't reliably produce a second
    // valuesChanged once that data lands. Waiting a short beat and then
    // recomputing directly sidesteps that gap.
    property int refreshTrigger: 0

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            var relevant = ["openwindow", "closewindow", "movewindow", "workspace"]
            if (relevant.indexOf(event.name) >= 0) refreshDelayTimer.restart()
        }
    }

    Timer {
        id: refreshDelayTimer
        interval: 350
        repeat: false
        onTriggered: {
            Hyprland.refreshToplevels()
            root.refreshTrigger++
        }
    }

    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: Config.workspaceSpacing

        Repeater {
            // Just the workspace numbers — the icon shown per slot is now
            // fully dynamic (see displayIcons below): whatever app(s) are
            // actually running there, or a neutral empty-workspace dot when
            // there's nothing open. Showing the app that's *pinned* to an
            // empty workspace (e.g. a grayed-out Bruno icon after quitting
            // it) reads like a lingering/zombie state, so that fallback was
            // dropped in favor of this simpler, always-accurate indicator.
            model: defaultIcon !== "" ? [
                {num: startWorkspace + 0},
                {num: startWorkspace + 1},
            ] : [
                {num: startWorkspace + 0},
                {num: startWorkspace + 1},
                {num: startWorkspace + 2},
                {num: startWorkspace + 3},
                {num: startWorkspace + 4},
            ]

            delegate: Item {
                id: cell
                property int workspaceNum: modelData.num
                property bool isActive: false

                // Depends on root.refreshTrigger (bumped on any relevant
                // Hyprland event) rather than reading Hyprland.toplevels
                // directly in a way that relies on its own change
                // notifications — see the comment on refreshTrigger above.
                readonly property var windowClasses: {
                    var _trigger = root.refreshTrigger
                    return root.windowClassesForWorkspace(workspaceNum)
                }

                readonly property bool hasWindows: windowClasses.length > 0

                readonly property var displayIcons: hasWindows
                    ? windowClasses.map(function(c) { return root.glyphForClass(c) })
                    : [root.plainGlyph(defaultIcon !== "" ? defaultIcon : Icon.emptyWorkspace)]

                Binding on isActive {
                    value: {
                        if (!Hyprland.focusedWorkspace) return false
                        return Hyprland.focusedWorkspace.id === workspaceNum
                    }
                    when: Hyprland.focusedWorkspace !== undefined
                }

                width: Math.max(Config.workspaceSize,
                    iconRow.implicitWidth + (Config.workspaceSize - Config.workspaceIconSize))
                height: Config.workspaceSize

                Row {
                    id: iconRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: cell.displayIcons

                        delegate: Text {
                            required property var modelData

                            anchors.horizontalCenterOffset: modelData.offsetX
                            text: modelData.char
                            color: cell.isActive ? Config.workspaceActive :
                                   (wsMouseArea.containsMouse ? Config.workspaceActive :
                                   (cell.hasWindows ? Config.moduleText : Config.moduleTextMuted))
                            font.pixelSize: Config.workspaceIconSize
                            font.family: modelData.font || Config.moduleFontFamily

                            Behavior on color {
                                ColorAnimation { duration: Config.animationDuration }
                            }
                        }
                    }
                }

                MouseArea {
                    id: wsMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    z: 1
                    onClicked: {
                        Hyprland.dispatch("workspace " + workspaceNum)
                    }
                }
            }
        }
    }
}
