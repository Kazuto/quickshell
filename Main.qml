import QtQuick
import Quickshell
import Quickshell.Io

import "root:/"
import "./modules" as Modules
import "./windows" as Windows
import "./overlays" as Overlays
import "./components" as Components

Rectangle {
    anchors.fill: parent
    color: "transparent"

    Component.onCompleted: {
        // Use the bar's screen width for overlay positioning
        var barScreen = Quickshell.screens.find(s => s.name === "HDMI-A-1")
            || Quickshell.screens.find(s => s.primary)
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

    function screenByName(name) {
        const s = Quickshell.screens.find(s => s.name === name)

        if (!s) console.warn(`No screen found for name ${name}, available:`,
            Quickshell.screens.map(s => s.name))

        return s
    }

    // Bar (Secondary Display - Workspaces Only)
    Windows.Bar {
        id: barSecondary
        screen:screenByName("DVI-I-2") 

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
        screen: screenByName("DVI-I-1")

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

    // Notifications overlay
    Overlays.NotificationsOverlay {
        id: notificationsOverlay
        visible: AppState.notificationsOverlayVisible
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
                    } else if (msg === "power-toggle") {
                        AppState.togglePowerOverlay()
                    } else if (msg === "spotify-toggle") {
                        AppState.toggleSpotifyOverlay()
                    } else if (msg === "spotify-show") {
                        if (!AppState.spotifyOverlayVisible) {
                            AppState.closeAllOverlays()
                        }
                        AppState.spotifyOverlayVisible = true
                    } else if (msg === "spotify-hide") {
                        AppState.spotifyOverlayVisible = false
                    } else {
                        console.log("Unknown command:", msg)
                    }
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
