pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    // Where the older, non-island overlays open: centered under the island of
    // this screen. lastClickX/screenWidth are what they position themselves by.
    property int lastClickX: 0
    property int screenWidth: 1920
    property var overlayScreen: null

    // Panel grown out of the island, "" when closed. One at a time: opening
    // another morphs the same outline instead of stacking.
    property string islandPanel: ""
    property string islandPanelOutput: ""

    // Panels that take over the screen: wider, dimmed behind, opened by keybind
    readonly property var keybindPanels: ["launcher", "emoji", "quick", "hotkeys", "wallpaper", "clipboard"]
    readonly property bool islandPanelDims: keybindPanels.indexOf(islandPanel) >= 0

    // Hyprland.focusedMonitor stays null on this build, but workspaces know both
    readonly property string focusedOutput: {
        var list = Hyprland.workspaces.values
        for (var i = 0; i < list.length; i++) {
            if (list[i].focused && list[i].monitor) return list[i].monitor.name
        }
        return ""
    }

    // Hyprland's description per output name. Qt reports no serial and two of the
    // monitors are the same model, so only hyprctl can tell them apart.
    property var outputDescriptions: ({})

    Process {
        id: monitorsProcess
        running: true
        command: ["hyprctl", "monitors", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const map = {}
                    for (const m of JSON.parse(this.text)) map[m.name] = m.description
                    outputDescriptions = map
                } catch (e) {
                    console.warn("Failed to parse hyprctl monitors output:", e)
                }
            }
        }
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            monitorsProcess.running = false
            monitorsProcess.running = true
        }
    }

    onFocusedOutputChanged: {
        if (islandPanel !== "" && focusedOutput !== "" && focusedOutput !== islandPanelOutput)
            closePanel()
    }

    function openPanel(name, output) {
        closeOlderOverlays()
        islandPanelOutput = output || focusedOutput
        islandPanel = name
    }

    function togglePanel(name, output) {
        if (islandPanel === name) closePanel()
        else openPanel(name, output)
    }

    function closePanel() {
        islandPanel = ""
    }

    function focusedScreen() {
        for (var i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === focusedOutput) return Quickshell.screens[i]
        }
        return Quickshell.screens[0] || null
    }

    function centerOverlaysOn(screen) {
        if (!screen) return
        overlayScreen = screen
        screenWidth = screen.width
        lastClickX = screen.width / 2
    }

    property bool ollamaOverlayVisible: false
    property bool trayMenuOverlayVisible: false
    // The QsMenuHandle (item.menu) of whichever tray icon was right-clicked
    property var trayMenuTarget: null

    function closeAllOverlays() {
        islandPanel = ""
        closeOlderOverlays()
    }

    function closeOlderOverlays() {
        ollamaOverlayVisible = false
        trayMenuOverlayVisible = false
    }

    function toggleOllamaOverlay() {
        if (!ollamaOverlayVisible) {
            closeAllOverlays()
        }
        ollamaOverlayVisible = !ollamaOverlayVisible
    }

    function openTrayMenu(menu) {
        closeAllOverlays()
        trayMenuTarget = menu
        trayMenuOverlayVisible = true
    }

    function closeTrayMenu() {
        trayMenuOverlayVisible = false
        trayMenuTarget = null
    }
}
