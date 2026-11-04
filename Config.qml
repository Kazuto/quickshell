pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // Helper function for color transparency
    function alpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    // Island geometry
    readonly property int islandHeight: 36
    readonly property int islandTransientHeight: 56
    readonly property int islandCompactHeight: 28
    readonly property int islandMarginTop: 8
    readonly property int islandBubbleGap: 8
    // Fixed surface big enough for the widest panel or pill plus both bubbles.
    // The window's input mask keeps everything outside the outline click-through.
    readonly property int islandSurfaceWidth: 1320
    readonly property int islandSurfaceHeight: 780

    readonly property int panelWidth: 440
    readonly property int panelWideWidth: 640
    readonly property int panelFullWidth: 1280
    readonly property int panelRadius: 24
    readonly property int panelPadTop: 8
    readonly property int panelPadSide: 20
    readonly property int panelPadBottom: 20
    readonly property int panelHeaderHeight: 36
    readonly property int cardRadius: 16
    readonly property int controlRadius: 12

    // Island motion
    readonly property int morphOpenMs: 320
    readonly property int morphCloseMs: 220
    readonly property int widthChangeMs: 260
    readonly property int contentFadeInMs: 140
    readonly property int contentFadeInDelayMs: 80
    readonly property int contentFadeOutMs: 80
    readonly property int notificationHoldMs: 4000
    readonly property int osdHoldMs: 1500
    readonly property var curveSpring: [0.2, 0.9, 0.25, 1.08, 1, 1]
    readonly property var curveEaseIn: [0.4, 0, 1, 1, 1, 1]
    readonly property var curveEaseOut: [0, 0, 0.2, 1, 1, 1]

    // Which workspaces each output shows, mirroring the Hyprland config's workspace rules.
    // Matched on the stable part of the monitor's description, since Hyprland's
    // DP-x names can change across reconnects.
    readonly property var workspaceLayout: [
        { match: "25355B006220", start: 6, count: 2 },
        { match: "25465B003652", start: 8, count: 2 }
    ]

    function workspaceSlots(description) {
        var layout = { start: 1, count: 5 }
        for (var i = 0; i < workspaceLayout.length; i++)
            if ((description || "").indexOf(workspaceLayout[i].match) >= 0) layout = workspaceLayout[i]
        var slots = []
        for (var n = 0; n < layout.count; n++) slots.push(layout.start + n)
        return slots
    }

    // QS_DEV=1 lets a second instance run beside the live shell from a worktree
    // without taking over its IPC socket or reserving screen space.
    readonly property bool devMode: Quickshell.env("QS_DEV") === "1"
    readonly property string ipcSocketPath: devMode ? "/tmp/quickshell-dev.sock" : "/tmp/quickshell.sock"

    // Bar settings
    readonly property int barHeight: islandHeight
    readonly property int barMarginTop: islandMarginTop
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
    readonly property int overlayRadius: panelRadius

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
