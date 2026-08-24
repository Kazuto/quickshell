pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // Helper function for color transparency
    function alpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    // Bar settings
    readonly property int barHeight: 34
    readonly property int barMarginTop: 14
    readonly property int barMarginSide: 6
    readonly property int barRadius: 12
    readonly property int barBorderWidth: 1

    // Workspace settings
    readonly property int workspaceSize: 32
    readonly property int workspaceRadius: 8
    readonly property int workspaceSpacing: 4
    readonly property int workspaceIconSize: 16

    // Module settings
    readonly property int moduleSpacing: 8
    readonly property int moduleHorizontalPadding: 24
    readonly property int moduleRadius: 10
    readonly property int moduleFontSize: 12
    readonly property string moduleFontFamily: "JetBrainsMono Nerd Font"

    // Overlay settings
    readonly property int overlayRadius: 10

    // Clock settings
    readonly property bool clock24Hour: false
    readonly property bool clockShowSeconds: false
    readonly property string clockFormat: " ddd dd MMM h:mm AP"

    // Tooltip settings
    readonly property int tooltipFontSize: 11
    readonly property int tooltipPadding: 8
    readonly property int tooltipRadius: 6
    readonly property int tooltipMargin: 4

    // Colors (can override theme colors if needed)
    readonly property color barBackground: Theme.base
    readonly property color barBorder: Theme.surface1
    readonly property color moduleBackground: Theme.base
    readonly property color moduleHoverBackground: Theme.surface0
    readonly property color moduleText: Theme.subtext1
    readonly property color moduleTextMuted: Theme.overlay1

    readonly property color workspaceActive: Theme.peach
    readonly property color workspaceActiveText: Theme.base
    readonly property color workspaceInactive: Theme.surface0
    readonly property color workspaceInactiveText: Theme.text
    readonly property color workspaceHasWindows: Theme.surface1
    readonly property color workspaceBorder: Theme.surface1

    // Animation settings
    readonly property int animationDuration: 150
}
