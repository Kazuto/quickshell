import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "root:/"
import "root:/singletons"
import "root:/components"

PanelWindow {
    id: batteryOverlay

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // ── data ────────────────────────────────────────────────────────────────
    property int   capacity:     0
    property int   energyNow:    0   // µWh
    property int   energyFull:   0   // µWh
    property int   energyDesign: 0   // µWh
    property int   powerNow:     0   // µW
    property int   cycleCount:   0
    property int   chargeStop:   100
    property string battStatus:  "Unknown"  // Charging | Discharging | Not charging | Full

    property string activeProfile: "balanced"
    readonly property var profiles: ["power-saver", "balanced", "performance"]
    readonly property var profileIcons: ({ "power-saver": "󰾆", "balanced": "󰾅", "performance": "󰓅" })
    readonly property var profileLabels: ({ "power-saver": "Power Saver", "balanced": "Balanced", "performance": "Performance" })

    // ── derived state ────────────────────────────────────────────────────────
    readonly property bool isCharging:    battStatus === "Charging"
    readonly property bool isFull:        battStatus === "Full" || (battStatus === "Not charging" && capacity >= chargeStop - 2)
    readonly property bool isDischarging: battStatus === "Discharging"
    readonly property bool thresholdActive: chargeStop < 100 && !isDischarging

    readonly property real fraction: energyFull > 0 ? Math.min(1.0, energyNow / energyFull) : capacity / 100

    // watts as a string e.g. "12.4 W"
    readonly property string rateText: powerNow > 0 ? (powerNow / 1000000).toFixed(1) + " W" : "—"

    // time remaining / to full
    readonly property string timeText: {
        if (powerNow <= 0) return "—"
        if (isDischarging) {
            var h = energyNow / powerNow
            var hh = Math.floor(h)
            var mm = Math.floor((h - hh) * 60)
            return hh + "h " + mm + "m left"
        }
        if (isCharging) {
            var needed = energyFull - energyNow
            if (needed <= 0) return "—"
            var h2 = needed / powerNow
            var hh2 = Math.floor(h2)
            var mm2 = Math.floor((h2 - hh2) * 60)
            return hh2 + "h " + mm2 + "m to full"
        }
        return "—"
    }

    readonly property string sizeText: energyDesign > 0 ? (energyDesign / 1000000).toFixed(0) + " Wh" : "—"

    readonly property color batteryColor: {
        if (isCharging || isFull) return Theme.green
        if (capacity <= 10) return Theme.red
        if (capacity <= 25) return Theme.peach
        if (capacity <= 50) return Theme.yellow
        return Theme.blue
    }

    readonly property string iconName: {
        if (isCharging) return "battery-charging"
        if (capacity >= 90) return "battery-full"
        if (capacity >= 60) return "battery-high"
        if (capacity >= 35) return "battery-medium"
        if (capacity >= 15) return "battery-low"
        if (capacity > 5)  return "battery-empty"
        return "battery-warning"
    }

    // ── rotating status phrases ──────────────────────────────────────────────
    readonly property var chargingPhrases:    ["Pumping power", "Injecting electrons", "Pouring juice", "Amassing watts", "Soaking amps"]
    readonly property var dischargingPhrases: ["Slurping power", "Spending joules", "Draining watts", "Sipping juice", "Burning electrons"]
    property int phraseIndex: 0

    readonly property var activePhrases: {
        if (isFull) return []
        if (isCharging) return chargingPhrases
        if (isDischarging) return dischargingPhrases
        return []
    }

    readonly property string heroStatus: {
        if (isFull) return "FULLY CHARGED"
        if (thresholdActive && !isCharging && !isDischarging) return "CHARGE LIMITED"
        if (activePhrases.length > 0) return activePhrases[phraseIndex % activePhrases.length].toUpperCase()
        return battStatus.toUpperCase()
    }

    // phrase fade animation
    SequentialAnimation {
        id: phraseSwap
        PropertyAnimation { target: statusText; property: "opacity"; to: 0; duration: 180; easing.type: Easing.OutQuad }
        ScriptAction { script: { if (activePhrases.length > 0) phraseIndex = (phraseIndex + 1) % activePhrases.length } }
        PropertyAnimation { target: statusText; property: "opacity"; to: 1; duration: 260; easing.type: Easing.InQuad }
    }

    Timer {
        interval: 2800
        running: batteryOverlay.visible && activePhrases.length > 0
        repeat: true
        onTriggered: phraseSwap.restart()
    }

    // ── data refresh ─────────────────────────────────────────────────────────
    function refresh() {
        batteryProc.running = false
        batteryProc.running = true
        profileProc.running = false
        profileProc.running = true
    }

    Process {
        id: batteryProc
        command: ["sh", "-c", [
            "cat /sys/class/power_supply/BAT0/capacity",
            "cat /sys/class/power_supply/BAT0/status",
            "cat /sys/class/power_supply/BAT0/energy_now",
            "cat /sys/class/power_supply/BAT0/energy_full",
            "cat /sys/class/power_supply/BAT0/energy_full_design",
            "cat /sys/class/power_supply/BAT0/power_now",
            "cat /sys/class/power_supply/BAT0/cycle_count",
            "cat /sys/class/power_supply/BAT0/charge_control_end_threshold 2>/dev/null || echo 100"
        ].join("; ")]
        stdout: SplitParser {
            property int lineNum: 0
            onRead: line => {
                var v = line.trim()
                switch (lineNum) {
                    case 0: batteryOverlay.capacity     = parseInt(v) || 0; break
                    case 1: batteryOverlay.battStatus   = v; break
                    case 2: batteryOverlay.energyNow    = parseInt(v) || 0; break
                    case 3: batteryOverlay.energyFull   = parseInt(v) || 0; break
                    case 4: batteryOverlay.energyDesign = parseInt(v) || 0; break
                    case 5: batteryOverlay.powerNow     = parseInt(v) || 0; break
                    case 6: batteryOverlay.cycleCount   = parseInt(v) || 0; break
                    case 7: batteryOverlay.chargeStop   = parseInt(v) || 100; break
                }
                lineNum++
            }
        }
        onExited: batteryProc.stdout.lineNum = 0
    }

    Process {
        id: profileProc
        command: ["sh", "-c", "powerprofilesctl get"]
        stdout: SplitParser {
            onRead: line => { batteryOverlay.activeProfile = line.trim() }
        }
    }

    Process {
        id: setProfileProc
        onExited: batteryOverlay.refresh()
    }

    function setProfile(p) {
        setProfileProc.command = ["powerprofilesctl", "set", p]
        setProfileProc.running = false
        setProfileProc.running = true
    }

    Timer {
        interval: 5000
        running: batteryOverlay.visible
        repeat: true
        onTriggered: batteryOverlay.refresh()
    }

    onVisibleChanged: { if (visible) { phraseIndex = 0; refresh() } }

    // ── UI ───────────────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: AppState.toggleBatteryOverlay()
        z: -1
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 12
            rightMargin: Math.min(AppState.screenWidth - 360 - 10, Math.max(10, AppState.screenWidth - AppState.lastClickX - 360 / 2))
        }
        width: 360
        height: content.implicitHeight + 40
        color: Theme.mantle
        radius: Config.overlayRadius
        border.color: Theme.surface0
        border.width: 1

        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
            id: content
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 20
            }
            spacing: 16

            // ── Hero row ──────────────────────────────────────────────────
            Row {
                width: parent.width
                spacing: 14

                SvgIcon {
                    name: batteryOverlay.iconName
                    size: 44
                    color: batteryOverlay.batteryColor
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    width: parent.width - 44 - 14 - heroPercent.width - 10

                    Text {
                        text: "Battery"
                        color: Theme.text
                        font.pixelSize: 16
                        font.bold: true
                        font.family: Config.moduleFontFamily
                    }

                    Text {
                        id: statusText
                        text: batteryOverlay.heroStatus
                        color: Theme.subtext0
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.2
                        font.family: Config.moduleFontFamily
                    }
                }

                Text {
                    id: heroPercent
                    text: batteryOverlay.capacity + "%"
                    color: batteryOverlay.batteryColor
                    font.pixelSize: 32
                    font.bold: true
                    font.family: Config.moduleFontFamily
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }

            // ── Progress bar ──────────────────────────────────────────────
            Item {
                width: parent.width
                height: 8

                Rectangle {
                    id: barTrack
                    anchors.fill: parent
                    radius: height / 2
                    color: Theme.surface0
                }

                Rectangle {
                    anchors.left: barTrack.left
                    anchors.verticalCenter: barTrack.verticalCenter
                    height: barTrack.height
                    radius: barTrack.radius
                    color: batteryOverlay.batteryColor
                    width: Math.max(height, barTrack.width * batteryOverlay.fraction)

                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 300 } }

                    SequentialAnimation on opacity {
                        running: batteryOverlay.isCharging && !batteryOverlay.isFull && batteryOverlay.visible
                        loops: Animation.Infinite
                        alwaysRunToEnd: true
                        NumberAnimation { from: 1.0; to: 0.45; duration: 950; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.45; to: 1.0; duration: 950; easing.type: Easing.InOutSine }
                    }
                }
            }

            // ── Stats grid ────────────────────────────────────────────────
            Row {
                width: parent.width
                spacing: 16

                Column {
                    width: (parent.width - parent.spacing) / 2
                    spacing: 8

                    StatRow { label: "Capacity";      value: batteryOverlay.sizeText }
                    StatRow { label: "Charge cycles"; value: batteryOverlay.cycleCount > 0 ? batteryOverlay.cycleCount + "" : "—" }
                    StatRow {
                        label: batteryOverlay.thresholdActive ? "Charge limit" : "Health"
                        value: batteryOverlay.thresholdActive
                            ? batteryOverlay.chargeStop + "%"
                            : (batteryOverlay.energyDesign > 0
                                ? Math.round(batteryOverlay.energyFull / batteryOverlay.energyDesign * 100) + "%"
                                : "—")
                    }
                }

                Column {
                    width: (parent.width - parent.spacing) / 2
                    spacing: 8

                    StatRow {
                        label: batteryOverlay.isDischarging ? "Time left" : (batteryOverlay.isCharging ? "Time to full" : "Time")
                        value: batteryOverlay.timeText
                    }
                    StatRow {
                        label: batteryOverlay.isDischarging ? "Discharging" : "Charging"
                        value: batteryOverlay.rateText
                    }
                    StatRow { label: "Status"; value: batteryOverlay.battStatus }
                }
            }

            // ── Divider ───────────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.surface0
            }

            // ── Power profiles ────────────────────────────────────────────
            Column {
                width: parent.width
                spacing: 10

                Text {
                    text: "POWER PROFILE"
                    color: Theme.overlay0
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.5
                    font.family: Config.moduleFontFamily
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: batteryOverlay.profiles

                        Rectangle {
                            required property string modelData
                            required property int index
                            width: (parent.width - 16) / 3
                            height: 52
                            radius: Config.moduleRadius
                            color: batteryOverlay.activeProfile === modelData ? Config.alpha(Theme.blue, 0.18) : Theme.surface0
                            border.color: batteryOverlay.activeProfile === modelData ? Theme.blue : (profileMouse.containsMouse ? Theme.surface2 : "transparent")
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: batteryOverlay.profileIcons[modelData] || "?"
                                    color: batteryOverlay.activeProfile === modelData ? Theme.blue : Theme.subtext1
                                    font.pixelSize: 18
                                    font.family: Config.moduleFontFamily

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: batteryOverlay.profileLabels[modelData] || modelData
                                    color: batteryOverlay.activeProfile === modelData ? Theme.blue : Theme.subtext0
                                    font.pixelSize: 10
                                    font.family: Config.moduleFontFamily

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                id: profileMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: batteryOverlay.setProfile(modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    // ── StatRow helper component ─────────────────────────────────────────────
    component StatRow: Row {
        property string label: ""
        property string value: ""
        width: parent.width
        spacing: 4

        Text {
            text: label + ":"
            color: Theme.overlay1
            font.pixelSize: 11
            font.family: Config.moduleFontFamily
        }
        Text {
            text: value
            color: Theme.subtext1
            font.pixelSize: 11
            font.family: Config.moduleFontFamily
        }
    }
}
