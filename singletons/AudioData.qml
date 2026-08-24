pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property int outputVolume: 0
    property bool outputMuted: false
    property int inputVolume: 0
    property bool inputMuted: false
    property string defaultSink: ""
    property string defaultSource: ""
    property var sinks: []
    property var sources: []

    function refreshDevices() {
        devicesProcess.running = false
        devicesProcess.running = true
    }

    function setOutputVolume(volume) {
        commandProcess.command = ["pamixer", "--set-volume", Math.round(volume).toString()]
        commandProcess.running = true
    }

    function setInputVolume(volume) {
        commandProcess.command = ["pamixer", "--default-source", "--set-volume", Math.round(volume).toString()]
        commandProcess.running = true
    }

    function toggleOutputMute() {
        commandProcess.command = ["pamixer", "-t"]
        commandProcess.running = true
    }

    function toggleInputMute() {
        commandProcess.command = ["pamixer", "--default-source", "-t"]
        commandProcess.running = true
    }

    function setDefaultSink(name) {
        commandProcess.command = ["pactl", "set-default-sink", name]
        commandProcess.running = true
    }

    function setDefaultSource(name) {
        commandProcess.command = ["pactl", "set-default-source", name]
        commandProcess.running = true
    }

    function setSinkVolume(name, volume) {
        // Update volume in array immediately for responsive UI
        var updated = []
        for (var i = 0; i < sinks.length; i++) {
            if (sinks[i].name === name) {
                updated.push({
                    name: sinks[i].name,
                    description: sinks[i].description,
                    volume: Math.round(volume),
                    muted: sinks[i].muted
                })
            } else {
                updated.push(sinks[i])
            }
        }
        sinks = updated

        commandProcess.command = ["pactl", "set-sink-volume", name, volume + "%"]
        commandProcess.running = true
    }

    function setSourceVolume(name, volume) {
        // Update volume in array immediately for responsive UI
        var updated = []
        for (var i = 0; i < sources.length; i++) {
            if (sources[i].name === name) {
                updated.push({
                    name: sources[i].name,
                    description: sources[i].description,
                    volume: Math.round(volume),
                    muted: sources[i].muted
                })
            } else {
                updated.push(sources[i])
            }
        }
        sources = updated

        commandProcess.command = ["pactl", "set-source-volume", name, volume + "%"]
        commandProcess.running = true
    }

    function toggleSinkMute(name) {
        commandProcess.command = ["pactl", "set-sink-mute", name, "toggle"]
        commandProcess.running = true
    }

    function toggleSourceMute(name) {
        commandProcess.command = ["pactl", "set-source-mute", name, "toggle"]
        commandProcess.running = true
    }

    Process {
        id: commandProcess
        running: false
        onExited: updateTimer.start()
    }

    Timer {
        id: updateTimer
        interval: 300
        running: false
        repeat: false
        onTriggered: {
            statusProcess.running = false
            statusProcess.running = true
            // Don't refresh devices on every command - only when overlay opens
        }
    }

    // Get volume and mute status
    Process {
        id: statusProcess
        running: true
        command: ["sh", "-c", `
            echo "OUTPUT_VOL:$(pamixer --get-volume)"
            echo "OUTPUT_MUTE:$(pamixer --get-mute)"
            echo "INPUT_VOL:$(pamixer --default-source --get-volume)"
            echo "INPUT_MUTE:$(pamixer --default-source --get-mute)"
            echo "DEFAULT_SINK:$(pactl get-default-sink)"
            echo "DEFAULT_SOURCE:$(pactl get-default-source)"
        `]

        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("OUTPUT_VOL:")) {
                    outputVolume = parseInt(data.substring(11)) || 0
                } else if (data.startsWith("OUTPUT_MUTE:")) {
                    outputMuted = data.substring(12) === "true"
                } else if (data.startsWith("INPUT_VOL:")) {
                    inputVolume = parseInt(data.substring(10)) || 0
                } else if (data.startsWith("INPUT_MUTE:")) {
                    inputMuted = data.substring(11) === "true"
                } else if (data.startsWith("DEFAULT_SINK:")) {
                    defaultSink = data.substring(13)
                } else if (data.startsWith("DEFAULT_SOURCE:")) {
                    defaultSource = data.substring(15)
                }
            }
        }
    }

    // Get list of devices
    Process {
        id: devicesProcess
        running: true
        command: ["sh", "-c", `
            # Output devices (sinks)
            pactl list sinks | awk '
                /Name:/ { name=$2 }
                /Description:/ { desc=$0; sub(/.*Description: /, "", desc) }
                /Mute:/ { mute=($2=="yes")?"true":"false" }
                /Volume:/ && name && desc && mute {
                    match($0, /([0-9]+)%/, arr)
                    vol=arr[1]
                    print "SINK|||" name "|||" desc "|||" vol "|||" mute
                    name=""; desc=""; vol=""; mute=""
                }
            '

            # Input devices (sources) - exclude monitors
            pactl list sources | awk '
                /Name:/ {
                    name=$2
                    if (name ~ /monitor/) { name=""; next }
                }
                /Description:/ && name { desc=$0; sub(/.*Description: /, "", desc) }
                /Mute:/ && name { mute=($2=="yes")?"true":"false" }
                /Volume:/ && name && desc && mute {
                    match($0, /([0-9]+)%/, arr)
                    vol=arr[1]
                    print "SOURCE|||" name "|||" desc "|||" vol "|||" mute
                    name=""; desc=""; vol=""; mute=""
                }
            '
        `]

        stdout: SplitParser {
            onRead: data => {
                var parts = data.split("|||")
                if (parts.length === 5) {
                    if (parts[0] === "SINK") {
                        sinks = sinks.concat([{
                            name: parts[1],
                            description: parts[2],
                            volume: parseInt(parts[3]) || 0,
                            muted: parts[4] === "true"
                        }])
                    } else if (parts[0] === "SOURCE") {
                        sources = sources.concat([{
                            name: parts[1],
                            description: parts[2],
                            volume: parseInt(parts[3]) || 0,
                            muted: parts[4] === "true"
                        }])
                    }
                }
            }
        }

        onRunningChanged: {
            if (running) {
                sinks = []
                sources = []
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            statusProcess.running = false
            statusProcess.running = true
            // Don't refresh devices every 2 seconds - only on demand
        }
    }

    Component.onCompleted: {
        statusProcess.running = true
        devicesProcess.running = true
    }
}
