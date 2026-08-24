pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property int totalSeconds: 0
    property int remainingSeconds: 0
    property bool running: false
    property bool isPaused: false

    property string displayTime: formatTime(remainingSeconds)

    function formatTime(seconds) {
        var mins = Math.floor(Math.abs(seconds) / 60)
        var secs = Math.abs(seconds) % 60
        var sign = seconds < 0 ? "-" : ""
        return sign + (mins < 10 ? "0" : "") + mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    function start(minutes) {
        totalSeconds = minutes * 60
        remainingSeconds = totalSeconds
        running = true
        isPaused = false
        timer.start()
    }

    function pause() {
        isPaused = true
        timer.stop()
    }

    function resume() {
        if (remainingSeconds > 0 || remainingSeconds < 0) {
            isPaused = false
            timer.start()
        }
    }

    function stop() {
        running = false
        isPaused = false
        remainingSeconds = 0
        totalSeconds = 0
        displayTime = formatTime(0)
        timer.stop()
    }

    function reset() {
        remainingSeconds = totalSeconds
        displayTime = formatTime(remainingSeconds)
        isPaused = false
        if (running) {
            timer.start()
        }
    }

    Timer {
        id: timer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            if (!isPaused && running) {
                remainingSeconds--
                displayTime = formatTime(remainingSeconds)

                // Notification when timer reaches 0
                if (remainingSeconds === 0) {
                    // Could send a notification here
                    console.log("Timer finished!")
                }
            }
        }
    }
}
