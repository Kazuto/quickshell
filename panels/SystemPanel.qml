import QtQuick
import Quickshell
import "root:/"
import "root:/singletons"
import "root:/components"

// F8: user@host in the control center's header, or Super Esc. Letters run an action
// as they did on the old power menu, including suspend, which has no button.
PanelFrame {
    id: panel

    // Action waiting for its second press
    property string armed: ""

    readonly property var actions: [
        { id: "lock", key: "L", label: "Lock", icon: "lock", command: ["hyprlock"] },
        { id: "logout", key: "E", label: "Log out", icon: "logout", command: ["killall", "Hyprland"] },
        { id: "reboot", key: "R", label: "Reboot", icon: "refresh", command: ["systemctl", "reboot"], confirm: true },
        { id: "shutdown", key: "S", label: "Shut down", icon: "power", command: ["systemctl", "poweroff"], confirm: true }
    ]

    backTo: "control"
    spacing: 12

    Component.onCompleted: SystemData.refresh()

    function press(action) {
        if (action.confirm && armed !== action.id) {
            armed = action.id
            disarmTimer.restart()
            return
        }
        armed = ""
        AppState.closePanel()
        Quickshell.execDetached(action.command)
    }

    function handleKey(event) {
        if (event.modifiers !== Qt.NoModifier) return
        var key = event.text.toUpperCase()
        if (key === "U") {
            AppState.closePanel()
            Quickshell.execDetached(["systemctl", "suspend"])
            event.accepted = true
            return
        }
        for (var i = 0; i < actions.length; i++) {
            if (actions[i].key === key) {
                press(actions[i])
                event.accepted = true
                return
            }
        }
    }

    Timer {
        id: disarmTimer
        interval: 3000
        repeat: false
        onTriggered: panel.armed = ""
    }

    headerLeft: [
        IslandLabel {
            text: "System"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        IslandLabel {
            text: SystemData.uptimeShort !== "" ? "up " + SystemData.uptimeShort : ""
            kind: "meta"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    DetailCard {
        width: parent.width
        labelWidth: 88
        rows: [
            { label: "OS", value: (SystemData.distro + " " + SystemData.distroVersion).trim() },
            { label: "Kernel", value: SystemData.kernel },
            { label: "WM", value: SystemData.de },
            { label: "Uptime", value: SystemData.uptime }
        ]
    }

    Grid {
        width: parent.width
        columns: 2
        spacing: 8

        Repeater {
            model: panel.actions

            delegate: IslandButton {
                required property var modelData

                readonly property bool isArmed: panel.armed === modelData.id

                width: (parent.width - parent.spacing) / 2
                implicitHeight: 48
                radius: 24
                iconName: modelData.icon
                label: isArmed ? "Press again" : modelData.label
                variant: isArmed ? "warn" : "raised"
                onClicked: panel.press(modelData)
            }
        }
    }

    IslandLabel {
        width: parent.width
        text: "Reboot and shut down need a second press within 3 s."
        kind: "meta"
    }
}
