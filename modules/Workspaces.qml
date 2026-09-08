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

    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: Config.workspaceSpacing

        Repeater {
            // Each workspace here mirrors the app hyprland.conf actually
            // pins to it via `exec-once = [workspace N silent] <app>`, so
            // the icon always matches what's really running there. This is
            // used as the *empty-workspace* fallback icon only — once a
            // workspace has real windows, it shows those apps' own icons
            // instead (see windowClassesForWorkspace above).
            model: defaultIcon !== "" ? [
                {num: startWorkspace + 0, icon: plainGlyph(defaultIcon)},
                {num: startWorkspace + 1, icon: plainGlyph(defaultIcon)},
            ] : [
                {num: startWorkspace + 0, icon: AppIcons.glyphFor("chrome") || plainGlyph(Icon.chrome)},      // google-chrome
                {num: startWorkspace + 1, icon: AppIcons.glyphFor("ghostty") || plainGlyph(Icon.ghostty)},    // ghostty
                {num: startWorkspace + 2, icon: AppIcons.glyphFor("tableplus") || plainGlyph(Icon.database)}, // tableplus
                {num: startWorkspace + 3, icon: AppIcons.glyphFor("bruno") || plainGlyph(Icon.code)},         // bruno
                {num: startWorkspace + 4, icon: AppIcons.glyphFor("protonmail") || plainGlyph(Icon.mail)},    // proton-mail
            ]

            delegate: Item {
                id: cell
                property int workspaceNum: modelData.num
                property var workspaceIcon: modelData.icon
                property bool isActive: false
                property var windowClasses: []

                // Derived from windowClasses (backed by Hyprland.toplevels)
                // rather than Hyprland.workspaces directly — the latter
                // doesn't reliably emit change notifications when a
                // workspace's window count changes, so a binding on it gets
                // stuck at its initial value instead of updating live.
                readonly property bool hasWindows: windowClasses.length > 0

                readonly property var displayIcons: hasWindows
                    ? windowClasses.map(function(c) { return root.glyphForClass(c) })
                    : [workspaceIcon]

                Binding on isActive {
                    value: {
                        if (!Hyprland.focusedWorkspace) return false
                        return Hyprland.focusedWorkspace.id === workspaceNum
                    }
                    when: Hyprland.focusedWorkspace !== undefined
                }

                Binding on windowClasses {
                    value: root.windowClassesForWorkspace(workspaceNum)
                    when: Hyprland.toplevels !== undefined
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
