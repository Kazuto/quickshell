import QtQuick
import Quickshell
import Quickshell.Io

import "root:/"
import "./singletons"
import "./windows" as Windows
import "./overlays" as Overlays

Rectangle {
    anchors.fill: parent
    color: "transparent"

    Component.onCompleted: {
        AppState.centerOverlaysOn(AppState.focusedScreen())
        console.log("QuickShell started with IPC on:", ipcSocket.path)
    }

    // Singletons start on first use. These collect history and counts a panel
    // should already have the first time it opens.
    readonly property var preloaded: [SystemStatsData, LogitechData, BatteryData, GitHubData]

    // One island per output; the scrim sits below it while a panel is open
    Variants {
        model: Quickshell.screens
        Windows.IslandScrim {}
    }

    Variants {
        model: Quickshell.screens
        Windows.Island {}
    }

    // Only exists while an area is being picked
    Variants {
        model: AreaSelectData.active ? Quickshell.screens : []
        Windows.AreaSelector {}
    }

    // Ollama overlay
    Overlays.OllamaOverlay {
        id: ollamaOverlay
        screen: AppState.overlayScreen
        visible: AppState.ollamaOverlayVisible
    }

    // System tray context menu
    Overlays.TrayMenuOverlay {
        id: trayMenuOverlay
        screen: AppState.overlayScreen
        visible: AppState.trayMenuOverlayVisible
    }

    // On a hot reload the outgoing generation removes the socket file as it shuts
    // down, right after the new one created it, which would leave every keybind
    // talking to nothing. Binding the socket a beat later avoids that race.
    Timer {
        interval: 500
        running: true
        onTriggered: ipcSocket.active = true
    }

    // IPC Socket Server
    SocketServer {
        id: ipcSocket
        path: Config.ipcSocketPath

        handler: Socket {
            id: client

            parser: SplitParser {
                onRead: msg => {
                    console.log("Received IPC command:", msg)

                    // Answers with "x,y wxh", or nothing if it was cancelled
                    if (msg === "area-select") {
                        AreaSelectData.pick(geometry => {
                            if (!client || !client.connected) return

                            client.write(geometry + "\n")
                            client.flush()
                            client.connected = false
                        })

                        return
                    }

                    // "<panel>-toggle" for every panel of the island
                    var panels = {
                        "spotify-toggle": "media",
                        "media-toggle": "media",
                        "notifications-toggle": "notifications",
                        "calendar-toggle": "calendar",
                        "timer-toggle": "timer",
                        "recorder-toggle": "recorder",
                        "control-toggle": "control",
                        "launcher-toggle": "launcher",
                        "emoji-toggle": "emoji",
                        "quick-toggle": "quick",
                        "hotkeys-toggle": "hotkeys",
                        "wallpaper-toggle": "wallpaper",
                        "clipboard-toggle": "clipboard",
                        "menu-toggle": "system",
                        "power-toggle": "system",
                        "system-toggle": "system",
                        "network-toggle": "network",
                        "bluetooth-toggle": "bluetooth",
                        "audio-toggle": "audio",
                        "vpn-toggle": "vpn",
                        "devices-toggle": "devices",
                        "battery-toggle": "battery",
                        "monitor-toggle": "monitor"
                    }

                    if (panels[msg]) {
                        AppState.togglePanel(panels[msg])

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
