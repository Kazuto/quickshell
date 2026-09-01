pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Current OSD state
    property string type: "volume"   // "volume" | "mute" | "brightness"
    property int value: 0            // 0–100
    property bool muted: false
    property bool visible: false

    // Hide timer
    property int hideDelay: 2000

    function showVolume(vol, isMuted) {
        value = vol
        muted = isMuted
        type = isMuted ? "mute" : "volume"
        visible = true
        hideTimer.restart()
    }

    function showBrightness(level) {
        value = level
        type = "brightness"
        visible = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: root.hideDelay
        repeat: false
        onTriggered: root.visible = false
    }
}
