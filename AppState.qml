pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property bool spotifyOverlayVisible: false
    property bool bluetoothOverlayVisible: false
    property bool audioOverlayVisible: false
    property bool notificationsOverlayVisible: false
    property bool controlCenterOverlayVisible: false
    property string controlCenterView: "main"  // main, bluetooth, audio
    property bool systemStatsOverlayVisible: false
    property bool githubOverlayVisible: false
    property bool timerOverlayVisible: false
    property bool ollamaOverlayVisible: false
    property bool calendarOverlayVisible: false
    property bool menuOverlayVisible: false
    property bool screenRecorderOverlayVisible: false
    property bool powerOverlayVisible: false
    property bool batteryOverlayVisible: false
    property bool isRecording: false

    function closeAllOverlays() {
        spotifyOverlayVisible = false
        bluetoothOverlayVisible = false
        audioOverlayVisible = false
        notificationsOverlayVisible = false
        controlCenterOverlayVisible = false
        systemStatsOverlayVisible = false
        githubOverlayVisible = false
        timerOverlayVisible = false
        ollamaOverlayVisible = false
        calendarOverlayVisible = false
        menuOverlayVisible = false
        screenRecorderOverlayVisible = false
        powerOverlayVisible = false
        batteryOverlayVisible = false
    }

    function toggleSpotifyOverlay() {
        if (!spotifyOverlayVisible) {
            closeAllOverlays()
        }
        spotifyOverlayVisible = !spotifyOverlayVisible
    }

    function toggleBluetoothOverlay() {
        if (!bluetoothOverlayVisible) {
            closeAllOverlays()
        }
        bluetoothOverlayVisible = !bluetoothOverlayVisible
    }

    function toggleAudioOverlay() {
        if (!audioOverlayVisible) {
            closeAllOverlays()
        }
        audioOverlayVisible = !audioOverlayVisible
    }

    function toggleNotificationsOverlay() {
        if (!notificationsOverlayVisible) {
            closeAllOverlays()
        }
        notificationsOverlayVisible = !notificationsOverlayVisible
    }

    function toggleControlCenterOverlay() {
        if (!controlCenterOverlayVisible) {
            closeAllOverlays()
        }
        controlCenterOverlayVisible = !controlCenterOverlayVisible
        if (controlCenterOverlayVisible) {
            controlCenterView = "main"
        }
    }

    function setControlCenterView(view) {
        controlCenterView = view
    }

    function toggleSystemStatsOverlay() {
        if (!systemStatsOverlayVisible) {
            closeAllOverlays()
        }
        systemStatsOverlayVisible = !systemStatsOverlayVisible
    }

    function toggleGitHubOverlay() {
        if (!githubOverlayVisible) {
            closeAllOverlays()
        }
        githubOverlayVisible = !githubOverlayVisible
    }

    function toggleTimerOverlay() {
        if (!timerOverlayVisible) {
            closeAllOverlays()
        }
        timerOverlayVisible = !timerOverlayVisible
    }

    function toggleOllamaOverlay() {
        if (!ollamaOverlayVisible) {
            closeAllOverlays()
        }
        ollamaOverlayVisible = !ollamaOverlayVisible
    }

    function toggleCalendarOverlay() {
        if (!calendarOverlayVisible) {
            closeAllOverlays()
        }
        calendarOverlayVisible = !calendarOverlayVisible
    }

    function toggleMenuOverlay() {
        if (!menuOverlayVisible) {
            closeAllOverlays()
        }
        menuOverlayVisible = !menuOverlayVisible
    }

    function toggleScreenRecorderOverlay() {
        if (!screenRecorderOverlayVisible) {
            closeAllOverlays()
        }
        screenRecorderOverlayVisible = !screenRecorderOverlayVisible
    }

    function togglePowerOverlay() {
        if (!powerOverlayVisible) {
            closeAllOverlays()
        }
        powerOverlayVisible = !powerOverlayVisible
    }

    function toggleBatteryOverlay() {
        if (!batteryOverlayVisible) {
            closeAllOverlays()
        }
        batteryOverlayVisible = !batteryOverlayVisible
    }
}
