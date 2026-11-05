pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Hyprland's commands depend on its config format: with a Lua config, dispatch takes Lua and
// eval replaces keyword. 0.57 only reads Lua while older releases, like Ubuntu's, only read
// hyprland.conf, so anything talking to Hyprland goes through here instead of picking a syntax.
Singleton {
    id: root

    property bool lua: false
    readonly property string configFile: lua ? "hyprland.lua" : "hyprland.conf"

    // Before 0.57 the pointer only reaches exclusive layers while one holds the keyboard. From
    // 0.57 it reaches every layer, and any exclusive layer under it takes the keyboard.
    property bool pointerReachesAllLayers: false

    // Stops a selection overlay fading out into a capture. The same rule grimblast sets.
    readonly property string selectionRuleCommand: lua
        ? `hyprctl eval 'hl.layer_rule({ match = { namespace = "^selection$" }, no_anim = true })'`
        : `hyprctl keyword layerrule 'match:namespace ^selection$, no_anim on'`

    function focusWorkspace(id) {
        Hyprland.dispatch(lua ? "hl.dsp.focus({ workspace = '" + id + "' })" : "workspace " + id)
    }

    function exec(command) {
        Quickshell.execDetached(lua
            ? ["hyprctl", "dispatch", "hl.dsp.exec_cmd(" + JSON.stringify(command) + ")"]
            : ["hyprctl", "dispatch", "exec", command])
    }

    function moveCursor(x, y) {
        Quickshell.execDetached(lua
            ? ["hyprctl", "dispatch", "hl.dsp.cursor.move({ x = " + x + ", y = " + y + " })"]
            : ["hyprctl", "dispatch", "movecursor", String(x), String(y)])
    }

    // Only a Lua config answers ok. Before 0.55 eval is an unknown request, and 0.55 and 0.56
    // refuse it while they're running a hyprland.conf.
    Process {
        running: true
        command: ["hyprctl", "eval", "local _ = 1"]
        stdout: StdioCollector {
            onStreamFinished: root.lua = this.text.trim() === "ok"
        }
    }

    Process {
        running: true
        command: ["hyprctl", "version", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const version = /^v?(\d+)\.(\d+)/.exec(JSON.parse(this.text).tag)
                    root.pointerReachesAllLayers = Number(version[1]) > 0 || Number(version[2]) >= 57
                } catch (e) {
                    console.warn("Could not read the Hyprland version:", e)
                }
            }
        }
    }
}
