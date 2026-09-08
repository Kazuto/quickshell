import QtQuick
import Quickshell
import Quickshell.Io

import "root:/"
import "./singletons"
import "./modules" as Modules
import "./windows" as Windows
import "./overlays" as Overlays
import "./components" as Components

Rectangle {
    anchors.fill: parent
    color: "transparent"

    // Maps monitor description (from `hyprctl monitors -j`) to its current
    // output name (e.g. "DP-8"). Hyprland's DP-x/HDMI-x names can change
    // across reconnects/reboots, but the description (make/model/serial) is
    // stable, so we resolve descriptions to names at runtime instead of
    // hardcoding names.
    property var monitorNameByDescription: ({})

    Process {
        id: monitorsProcess
        running: true
        command: ["hyprctl", "monitors", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const monitors = JSON.parse(this.text)
                    const map = {}
                    for (const m of monitors) map[m.description] = m.name
                    monitorNameByDescription = map
                } catch (e) {
                    console.warn("Failed to parse hyprctl monitors output:", e)
                }
            }
        }
    }

    Component.onCompleted: {
        // Use the bar's screen width for overlay positioning
        var barScreen = Quickshell.screens.find(s => s.primary)
            || Quickshell.screens[0]
        if (barScreen) AppState.screenWidth = barScreen.width
        console.log("QuickShell started with IPC on:", ipcSocket.path)
    }

    // Bar (Primary Display)
    Windows.Bar {
        id: bar

        leftItems: [
            Modules.Menu {},
            Modules.Workspaces {},
            Modules.WindowTitle {}
        ]

        centerItems: [
            Modules.Spotify {}
        ]

        rightItems: [
            Modules.Tray {},
            Components.ModuleGroup {
                items: [
                    Modules.Notifications { color: "transparent"; radius: 0 },
                    Components.ModuleDivider {},
                    Modules.Timer        { color: "transparent"; radius: 0 },
                    Components.ModuleDivider {},
                    Modules.ScreenRecorder { color: "transparent"; radius: 0 },
                    Components.ModuleDivider {},
                    Modules.GitHub       { color: "transparent"; radius: 0 },
                    Components.ModuleDivider {},
                    Modules.Logitech     { color: "transparent"; radius: 0 },
                    Components.ModuleDivider {},
                    Modules.Network      { color: "transparent"; radius: 0 },
                    Components.ModuleDivider {},
                    Modules.Wifi         { color: "transparent"; radius: 0 },
                    Components.ModuleDivider {},
                    Modules.Bluetooth    { color: "transparent"; radius: 0 },
                    Components.ModuleDivider {},
                    Modules.Audio        { color: "transparent"; radius: 0 },
                    Components.ModuleDivider {},
                    Modules.SystemStats  { color: "transparent"; radius: 0 },
                    Components.ModuleDivider {},
                    Modules.Battery      { color: "transparent"; radius: 0 },
                    Components.ModuleDivider {},
                    Modules.Clock        { color: "transparent"; radius: 0 },
                ]
            },
        ]
    }

    // Resolves a monitor by its stable hardware description (as used in
    // ~/.config/hypr/monitors.conf) rather than its Hyprland output name
    // (DP-x/HDMI-x), since output names can change across reconnects/reboots.
    function findScreenByDescription(description) {
        const name = monitorNameByDescription[description]

        if (!name) {
            console.warn(`No monitor name found for description "${description}", available:`,
                monitorNameByDescription)
            return undefined
        }

        const s = Quickshell.screens.find(s => s.name === name)

        if (!s) console.warn(`No screen found for ${name}, available:`,
            Quickshell.screens.map(s => s.name))

        return s
    }

    // Bar (Secondary Display - Workspaces Only)
    Windows.Bar {
        id: barSecondary
        screen: findScreenByDescription("GIGA-BYTE TECHNOLOGY CO. LTD. GS27QCA 25355B006220")

        leftItems: [
            Modules.Workspaces {
                startWorkspace: 6
                defaultIcon: Icon.emptyWorkspace
            }
        ]

        centerItems: []
        rightItems: []
    }

    // Bar (Third Display - Left Side - Workspaces Only)
    Windows.Bar {
        id: barTertiary
        screen: findScreenByDescription("GIGA-BYTE TECHNOLOGY CO. LTD. GS27QCA 25465B003652")

        leftItems: [
            Modules.Workspaces {
                startWorkspace: 8
                defaultIcon: Icon.emptyWorkspace
            }
        ]

        centerItems: []
        rightItems: []
    }

    // Spotify overlay
    Overlays.SpotifyOverlay {
        id: spotifyOverlay
        visible: AppState.spotifyOverlayVisible
    }

    // Bluetooth overlay
    Overlays.BluetoothOverlay {
        id: bluetoothOverlay
        visible: AppState.bluetoothOverlayVisible
    }

    // Audio overlay
    Overlays.AudioOverlay {
        id: audioOverlay
        visible: AppState.audioOverlayVisible
    }

    // Wifi overlay
    Overlays.WifiOverlay {
        id: wifiOverlay
        visible: AppState.wifiOverlayVisible
    }

    // VPN overlay
    Overlays.VpnOverlay {
        id: vpnOverlay
        visible: AppState.vpnOverlayVisible
    }

    // Logitech overlay
    Overlays.LogitechOverlay {
        id: logitechOverlay
        visible: AppState.logitechOverlayVisible
    }

    // Notifications overlay (history panel)
    Overlays.NotificationsOverlay {
        id: notificationsOverlay
        visible: AppState.notificationsOverlayVisible
    }

    // Notification toast popups (always active, manages its own visibility)
    Overlays.NotificationPopupsOverlay {
        id: notificationPopupsOverlay
    }

    // Control Center overlay removed — replaced by separate Wifi/Audio/Bluetooth overlays

    // System Stats overlay
    Overlays.SystemStatsOverlay {
        id: systemStatsOverlay
        visible: AppState.systemStatsOverlayVisible
    }

    // GitHub overlay
    Overlays.GitHubOverlay {
        id: githubOverlay
        visible: AppState.githubOverlayVisible
    }

    // Timer overlay
    Overlays.TimerOverlay {
        id: timerOverlay
        visible: AppState.timerOverlayVisible
    }

    // Ollama overlay
    Overlays.OllamaOverlay {
        id: ollamaOverlay
        visible: AppState.ollamaOverlayVisible
    }

    // Calendar overlay
    Overlays.CalendarOverlay {
        id: calendarOverlay
        visible: AppState.calendarOverlayVisible
    }

    // Menu overlay
    Overlays.MenuOverlay {
        id: menuOverlay
        visible: AppState.menuOverlayVisible
    }

    // Screen Recorder overlay
    Overlays.ScreenRecorderOverlay {
        id: screenRecorderOverlay
        visible: AppState.screenRecorderOverlayVisible
    }

    // Power overlay
    Overlays.PowerOverlay {
        id: powerOverlay
        visible: AppState.powerOverlayVisible
    }

    // Battery overlay
    Overlays.BatteryOverlay {
        id: batteryOverlay
        visible: AppState.batteryOverlayVisible
    }

    // App Launcher overlay
    Overlays.LauncherOverlay {
        id: launcherOverlay
        visible: AppState.launcherOverlayVisible
    }

    // Emoji Picker overlay
    Overlays.EmojiPickerOverlay {
        id: emojiPickerOverlay
        visible: AppState.emojiPickerOverlayVisible
    }

    // Wallpaper Picker overlay
    Overlays.WallpaperPickerOverlay {
        id: wallpaperPickerOverlay
        visible: AppState.wallpaperPickerOverlayVisible
    }

    // System tray context menu
    Overlays.TrayMenuOverlay {
        id: trayMenuOverlay
        visible: AppState.trayMenuOverlayVisible
    }

    // System tray hover tooltip
    Overlays.TrayTooltipOverlay {
        id: trayTooltipOverlay
    }

    // OSD (volume / brightness)
    Overlays.OsdOverlay {
        id: osdOverlay
    }

    // IPC Socket Server
    SocketServer {
        id: ipcSocket
        active: true
        path: "/tmp/quickshell.sock"

        handler: Socket {
            parser: SplitParser {
                onRead: msg => {
                    console.log("Received IPC command:", msg)

                    if (msg === "menu-toggle") {
                        AppState.toggleMenuOverlay()

                        return
                    }

                    if (msg === "power-toggle") {
                        AppState.togglePowerOverlay()

                        return
                    }

                    if (msg === "spotify-toggle") {
                        AppState.toggleSpotifyOverlay()

                        return
                    }

                    if (msg === "spotify-show") {
                        if (!AppState.spotifyOverlayVisible) {
                            AppState.closeAllOverlays()
                        }
                        AppState.spotifyOverlayVisible = true

                        return
                    }

                    if (msg === "spotify-hide") {
                        AppState.spotifyOverlayVisible = false

                        return
                    }

                    if (msg === "launcher-toggle") {
                        AppState.toggleLauncherOverlay()

                        return
                    }

                    if (msg === "emoji-toggle") {
                        AppState.toggleEmojiPickerOverlay()

                        return
                    }

                    if (msg === "wallpaper-toggle") {
                        AppState.toggleWallpaperPickerOverlay()

                        return
                    }

                    if (msg.startsWith("osd-volume:")) {
                        // "osd-volume:<0-100>:<muted|unmuted>"
                        var parts = msg.split(":")
                        OsdData.showVolume(parseInt(parts[1]) || 0, parts[2] === "muted")

                        return
                    }

                    if (msg.startsWith("osd-brightness:")) {
                        // "osd-brightness:<0-100>"
                        OsdData.showBrightness(parseInt(msg.split(":")[1]) || 0)

                        return
                    }
                    console.log("Unknown command:", msg)
                }
            }

            onConnectedChanged: {
                if (connected) {
                    console.log("IPC client connected")
                }
            }
        }
    }
}
