import QtQuick
import Quickshell
import Quickshell.Hyprland
import "root:/"
import "root:/js/AppIcons.js" as AppIcons

Rectangle {
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

    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: Config.workspaceSpacing

        Repeater {
            // Each workspace here mirrors the app hyprland.conf actually
            // pins to it via `exec-once = [workspace N silent] <app>`, so
            // the icon always matches what's really running there.
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
                property int workspaceNum: modelData.num
                property var workspaceIcon: modelData.icon
                property bool isActive: false
                property bool hasWindows: false

                Binding on isActive {
                    value: {
                        if (!Hyprland.focusedWorkspace) return false
                        return Hyprland.focusedWorkspace.id === workspaceNum
                    }
                    when: Hyprland.focusedWorkspace !== undefined
                }

                Binding on hasWindows {
                    value: {
                        for (var i in Hyprland.workspaces.values) {
                            var ws = Hyprland.workspaces.values[i]
                            if (ws.id === workspaceNum) {
                                return ws.windows && ws.windows.length > 0
                            }
                        }
                        return false
                    }
                    when: Hyprland.workspaces !== undefined
                }

                width: Config.workspaceSize
                height: Config.workspaceSize

                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: workspaceIcon.offsetX
                    text: workspaceIcon.char
                    color: isActive ? Config.workspaceActive :
                           (wsMouseArea.containsMouse ? Config.workspaceActive :
                           (hasWindows ? Config.moduleText : Config.moduleTextMuted))
                    font.pixelSize: Config.workspaceIconSize
                    font.family: workspaceIcon.font || Config.moduleFontFamily
                    z: 0

                    Behavior on color {
                        ColorAnimation { duration: Config.animationDuration }
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
