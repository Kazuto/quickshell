import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/singletons"
import "root:/components"
import "root:/modules" as Modules
import "root:/panels" as Panels
import "root:/js/KeyNav.js" as KeyNav

// One island per output, always top center. Activities, transients and panels
// only show on the focused output; the others drop to the compact pill.
PanelWindow {
    id: win

    required property var modelData

    readonly property string outputName: modelData.name
    readonly property bool focusedHere: AppState.focusedOutput === outputName || AppState.focusedOutput === ""
    readonly property bool panelHere: AppState.islandPanel !== "" && AppState.islandPanelOutput === outputName
    readonly property bool bubblesAllowed: focusedHere && main.width < Config.panelFullWidth - 100
    readonly property bool leftShown: bubblesAllowed && IslandData.leftBubble
    readonly property bool rightShown: bubblesAllowed && IslandData.rightBubble
    readonly property bool anyBubble: IslandData.leftBubble || IslandData.rightBubble

    readonly property string viewKey: {
        if (panelHere) return "panel-" + AppState.islandPanel
        if (!focusedHere) return "compact"
        return IslandData.core
    }

    screen: modelData
    anchors.top: true
    margins.top: Config.islandMarginTop
    implicitWidth: Math.min(modelData.width, Config.islandSurfaceWidth)
    implicitHeight: Math.min(modelData.height - Config.islandMarginTop, Config.islandSurfaceHeight)
    color: "transparent"
    exclusiveZone: Config.devMode ? 0 : Config.islandHeight

    WlrLayershell.namespace: "quickshell-island"
    // Taken only once raised: the surface that takes exclusive focus last gets the
    // keyboard and is the first one tested for pointer input, ahead of the scrim.
    WlrLayershell.keyboardFocus: panelHere && raised && !settling ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // At rest it stays under fullscreen windows like a bar. Anything that needs
    // to be seen moves up to Overlay.
    WlrLayershell.layer: !settling && (raised || (focusedHere && IslandData.transientActive))
        ? WlrLayer.Overlay : WlrLayer.Top

    mask: Region {
        item: main
        Region { item: leftBubble }
        Region { item: rightBubble }
    }

    // The scrim maps on the Overlay layer when a panel opens, and later surfaces
    // stack on top. Dropping down until it has mapped, then moving back up,
    // keeps the island above it even if a transient already had it on Overlay.
    property bool raised: false
    property bool settling: false

    onPanelHereChanged: {
        if (panelHere) {
            settling = true
            raiseTimer.restart()
            lowerTimer.stop()
            Qt.callLater(() => keyRoot.forceActiveFocus())
        } else {
            raiseTimer.stop()
            lowerTimer.restart()
        }
    }

    Timer {
        id: raiseTimer
        interval: 40
        repeat: false
        onTriggered: {
            win.raised = true
            win.settling = false
        }
    }

    Timer {
        id: lowerTimer
        interval: Config.contentFadeOutMs + Config.morphCloseMs + 40
        repeat: false
        onTriggered: win.raised = false
    }

    Item {
        id: keyRoot

        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (KeyNav.isEscape(event)) {
                AppState.closePanel()
                event.accepted = true
                return
            }
            var panel = main.view
            if (panel && panel.handleKey) panel.handleKey(event)
            if (!event.accepted && panel && panel.backTo && KeyNav.isBackspace(event)) {
                AppState.openPanel(panel.backTo)
                event.accepted = true
            }
        }

        Keys.onReleased: event => {
            var panel = main.view
            if (panel && panel.handleKeyRelease) panel.handleKeyRelease(event)
        }

        // Group stays centered at rest. Under a panel the panel itself holds
        // center and the bubbles flank its top row.
        readonly property real groupShift: {
            if (win.panelHere) return 0
            var left = win.leftShown ? leftContent.implicitWidth + Config.islandBubbleGap : 0
            var right = win.rightShown ? rightContent.implicitWidth + Config.islandBubbleGap : 0
            return (left - right) / 2
        }
        property real animatedShift: groupShift

        Behavior on animatedShift {
            NumberAnimation { duration: Config.widthChangeMs; easing.type: Easing.OutCubic }
        }

        IslandSurface {
            id: main

            x: (keyRoot.width - width) / 2 + keyRoot.animatedShift
            y: 0
            viewKey: win.viewKey
            views: ({
                "compact": compactView,
                "idle": idleView,
                "media": mediaView,
                "notification": notificationView,
                "osd": osdView,
                "panel-media": mediaPanel,
                "panel-notifications": notificationsPanel,
                "panel-calendar": calendarPanel,
                "panel-timer": timerPanel,
                "panel-recorder": recorderPanel,
                "panel-control": controlPanel,
                "panel-launcher": launcherPanel,
                "panel-emoji": emojiPanel,
                "panel-quick": quickPanel,
                "panel-hotkeys": hotkeysPanel,
                "panel-wallpaper": wallpaperPanel,
                "panel-clipboard": clipboardPanel,
                "panel-system": systemPanel,
                "panel-network": networkPanel,
                "panel-bluetooth": bluetoothPanel,
                "panel-audio": audioPanel,
                "panel-vpn": vpnPanel,
                "panel-devices": devicesPanel,
                "panel-battery": batteryPanel,
                "panel-monitor": monitorPanel
            })
        }

        Rectangle {
            id: leftBubble

            x: main.x - width - (width > 0 ? Config.islandBubbleGap : 0)
            y: 0
            width: win.leftShown ? leftContent.implicitWidth : 0
            height: Config.islandHeight
            radius: height / 2
            color: Theme.island
            border.width: 1
            border.color: Theme.stroke
            clip: true
            opacity: win.leftShown ? 1 : 0

            Behavior on width {
                NumberAnimation { duration: Config.widthChangeMs; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: Config.contentFadeInMs }
            }

            Modules.RecordingBubble {
                id: leftContent
                anchors.right: parent.right
                screen: win.modelData
            }
        }

        Rectangle {
            id: rightBubble

            x: main.x + main.width + (width > 0 ? Config.islandBubbleGap : 0)
            y: 0
            width: win.rightShown ? rightContent.implicitWidth : 0
            height: Config.islandHeight
            radius: height / 2
            color: Theme.island
            border.width: 1
            border.color: Theme.stroke
            clip: true
            opacity: win.rightShown ? 1 : 0

            Behavior on width {
                NumberAnimation { duration: Config.widthChangeMs; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: Config.contentFadeInMs }
            }

            Modules.TimerBubble {
                id: rightContent
                screen: win.modelData
                ringOnly: win.viewKey === "media"
            }
        }
    }

    Component { id: compactView; Modules.CompactPill { screen: win.modelData } }
    Component { id: idleView; Modules.IdlePill { screen: win.modelData; shrunk: win.anyBubble } }
    Component { id: mediaView; Modules.MediaPill { screen: win.modelData; shrunk: win.anyBubble } }
    Component { id: notificationView; Modules.NotificationPill { screen: win.modelData } }
    Component { id: osdView; Modules.OsdPill { screen: win.modelData } }

    Component { id: mediaPanel; Panels.MediaPanel {} }
    Component { id: notificationsPanel; Panels.NotificationsPanel {} }
    Component { id: calendarPanel; Panels.CalendarPanel {} }
    Component { id: timerPanel; Panels.TimerPanel {} }
    Component { id: recorderPanel; Panels.RecorderPanel {} }
    Component { id: controlPanel; Panels.ControlPanel { screen: win.modelData } }
    Component { id: launcherPanel; Panels.LauncherPanel {} }
    Component { id: emojiPanel; Panels.EmojiPanel {} }
    Component { id: quickPanel; Panels.QuickPanel {} }
    Component { id: hotkeysPanel; Panels.HotkeysPanel {} }
    Component { id: wallpaperPanel; Panels.WallpaperPanel { outputName: win.outputName } }
    Component { id: clipboardPanel; Panels.ClipboardPanel {} }
    Component { id: systemPanel; Panels.SystemPanel {} }
    Component { id: networkPanel; Panels.NetworkPanel {} }
    Component { id: bluetoothPanel; Panels.BluetoothPanel {} }
    Component { id: audioPanel; Panels.AudioPanel {} }
    Component { id: vpnPanel; Panels.VpnPanel {} }
    Component { id: devicesPanel; Panels.DevicesPanel {} }
    Component { id: batteryPanel; Panels.BatteryPanel {} }
    Component { id: monitorPanel; Panels.MonitorPanel {} }
}
