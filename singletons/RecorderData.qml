pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/"
import "root:/singletons"

Singleton {
    id: root

    property string captureMode: "screen"  // screen | window | area
    property string audioMode: "both"      // both | system | mic | none
    property string quality: "high"        // high | medium | low

    property bool recording: false
    property int elapsedSeconds: 0
    readonly property string elapsedText: {
        var mins = Math.floor(elapsedSeconds / 60)
        var secs = elapsedSeconds % 60
        return (mins < 10 ? "0" : "") + mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    readonly property string videosPath: Quickshell.env("HOME") + "/Videos"
    property string pendingMode: ""

    function start(mode) {
        if (recording) return
        pendingMode = mode || captureMode
        AppState.closePanel()
        // Wait out the panel's close so neither it nor the scrim end up on tape
        startDelay.restart()
    }

    function stop() {
        // SIGINT so wf-recorder finalizes the file
        recordingProcess.signal(2)
    }

    function openFolder() {
        Quickshell.execDetached(["xdg-open", videosPath])
    }

    Timer {
        id: startDelay
        interval: Config.morphCloseMs + 100
        repeat: false
        onTriggered: {
            if (root.pendingMode === "screen") {
                root.record(["-o", AppState.focusedOutput])
                return
            }
            if (root.pendingMode === "area") {
                AreaSelectData.pick(geometry => {
                    if (geometry.length > 0) root.record(["-g", geometry])
                })
                return
            }
            pickerProcess.command = ["sh", "-c", root.windowPicker]
            pickerProcess.running = true
        }
    }

    // Click a visible window: slurp -r restricts selection to the boxes on stdin.
    // The rule is the same as grimblast's, so the overlay can't fade out into the recording.
    readonly property string windowPicker: `
        hyprctl keyword layerrule 'match:namespace ^selection$, no_anim on' >/dev/null
        ws=$(hyprctl monitors -j | jq -c '[.[].activeWorkspace.id]')
        hyprctl clients -j | jq -r --argjson ws "$ws" '.[] | select(.workspace.id as $w | $ws | index($w)) | "\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])"' | slurp -r
    `

    Process {
        id: pickerProcess
        stdout: StdioCollector {
            onStreamFinished: {
                var geometry = this.text.trim()
                if (geometry.length > 0 && geometry.indexOf("cancelled") < 0)
                    root.record(["-g", geometry])
            }
        }
    }

    function audioArgs() {
        // wf-recorder takes a single source, so "both" records the system mix
        if (audioMode === "none") return []
        var device = audioMode === "mic" ? AudioData.defaultSource
            : (AudioData.defaultSink ? AudioData.defaultSink + ".monitor" : "")
        return device ? ["-a" + device] : []
    }

    function qualityArgs() {
        if (quality === "low") return ["-r", "30", "-p", "crf=28"]
        if (quality === "medium") return ["-r", "60", "-p", "crf=23"]
        return ["-r", "60", "-p", "crf=18"]
    }

    function record(targetArgs) {
        var timestamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, -5)
        Quickshell.execDetached(["mkdir", "-p", videosPath])
        recordingProcess.command = ["wf-recorder"]
            .concat(targetArgs, audioArgs(), ["-c", "libx264"], qualityArgs(),
                    ["-f", videosPath + "/recording_" + timestamp + ".mp4"])
        elapsedSeconds = 0
        recordingProcess.running = true
        recording = true
    }

    Process {
        id: recordingProcess
        onExited: root.recording = false
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.elapsedSeconds++
    }
}
