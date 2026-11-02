pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool present: false
    property int capacity: 100
    property string status: "Unknown"  // Charging, Discharging, Not charging, Full
    property int energyNow: 0          // µWh
    property int energyFull: 0
    property int energyDesign: 0
    property int powerNow: 0           // µW
    property int cycleCount: 0
    property int chargeStop: 100
    property string profile: ""

    readonly property bool isCharging: status === "Charging"
    readonly property bool isDischarging: status === "Discharging"
    readonly property bool isFull: status === "Full" || (status === "Not charging" && capacity >= chargeStop - 2)
    readonly property bool isLow: capacity <= 15 && !isCharging

    readonly property var profileIds: ["power-saver", "balanced", "performance"]
    readonly property var profileNames: ["Saver", "Balanced", "Performance"]
    readonly property string profileLabel: {
        var index = profileIds.indexOf(profile)
        return index >= 0 ? profileNames[index] : ""
    }

    readonly property string iconName: {
        if (isCharging) return "battery-charging"
        if (capacity >= 90) return "battery-full"
        if (capacity >= 60) return "battery-high"
        if (capacity >= 35) return "battery-medium"
        if (capacity >= 15) return "battery-low"
        if (capacity > 5) return "battery-empty"
        return "battery-warning"
    }

    function formatHours(hours) {
        var whole = Math.floor(hours)
        return whole + "h " + Math.floor((hours - whole) * 60) + "m"
    }

    readonly property string timeText: {
        if (powerNow <= 0) return "–"
        if (isDischarging) return formatHours(energyNow / powerNow)
        if (isCharging && energyFull > energyNow) return formatHours((energyFull - energyNow) / powerNow)
        return "–"
    }

    readonly property string capacityText: energyDesign > 0 ? (energyDesign / 1000000).toFixed(0) + " Wh" : "–"

    function refresh() {
        batteryProcess.running = false
        batteryProcess.running = true
    }

    function setProfile(id) {
        profile = id
        setProfileProcess.command = ["powerprofilesctl", "set", id]
        setProfileProcess.running = true
    }

    Process {
        id: setProfileProcess
        onExited: root.refresh()
    }

    Process {
        id: batteryProcess
        running: true
        command: ["sh", "-c", `
            cd /sys/class/power_supply/BAT0 2>/dev/null || exit 0
            cat capacity status energy_now energy_full energy_full_design power_now cycle_count
            cat charge_control_end_threshold 2>/dev/null || echo 100
            powerprofilesctl get 2>/dev/null
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                root.present = lines.length >= 8 && !isNaN(parseInt(lines[0], 10))
                if (!root.present) return
                root.capacity = parseInt(lines[0], 10)
                root.status = lines[1].trim()
                root.energyNow = parseInt(lines[2], 10) || 0
                root.energyFull = parseInt(lines[3], 10) || 0
                root.energyDesign = parseInt(lines[4], 10) || 0
                root.powerNow = parseInt(lines[5], 10) || 0
                root.cycleCount = parseInt(lines[6], 10) || 0
                root.chargeStop = parseInt(lines[7], 10) || 100
                root.profile = (lines[8] || "").trim()
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
