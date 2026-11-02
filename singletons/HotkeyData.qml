pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/js/Hotkeys.js" as Hotkeys

// The hotkey sheet's contents, and the chord each overlay header shows, read
// from the real config so neither can drift from what the keys actually do.
Singleton {
    id: root

    property var sections: []
    property var overlayKeys: ({})

    function keyFor(command, fallback) {
        return overlayKeys[command] || fallback || ""
    }

    FileView {
        id: configFile
        path: Quickshell.env("HOME") + "/.config/hypr/hyprland.conf"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            var parsed = Hotkeys.parse(text())
            root.sections = parsed.sections
            root.overlayKeys = parsed.overlayKeys
        }
    }
}
