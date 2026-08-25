import QtQuick
import Quickshell
import Quickshell.Io

import "root:/"
import "./modules" as Modules
import "./windows" as Windows
import "./overlays" as Overlays

Rectangle {
    anchors.fill: parent
    color: "transparent"

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
            Modules.GitHub {},
            Modules.Network {},
            Modules.Timer {},
            Modules.ScreenRecorder {},
            Modules.Logitech {},
            Modules.SystemStats {},
            Modules.ControlCenter {},
            Modules.Notifications {},
            Modules.Battery {},
            Modules.Clock {},
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

    // Notifications overlay
    Overlays.NotificationsOverlay {
        id: notificationsOverlay
        visible: AppState.notificationsOverlayVisible
    }

    // Control Center overlay
    Overlays.ControlCenterOverlay {
        id: controlCenterOverlay
        visible: AppState.controlCenterOverlayVisible
    }

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

    Component.onCompleted: {
        console.log("QuickShell started with IPC on:", ipcSocket.path)
    }
}
