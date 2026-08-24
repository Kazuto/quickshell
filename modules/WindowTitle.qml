import QtQuick
import Quickshell.Hyprland
import "root:/"

Rectangle {
    implicitWidth: Math.min(row.implicitWidth + Config.moduleHorizontalPadding, 300)
    implicitHeight: Config.barHeight
    color: Config.moduleBackground
    radius: Config.moduleRadius

    property var activeWindow: Hyprland.activeToplevel

    property string windowClass: {
        if (!activeWindow) return ""
        if (activeWindow.lastIpcObject) {
            return activeWindow.lastIpcObject.class || ""
        }
        return ""
    }

    // display label (unchanged from your original)
    property string displayText: {
        if (!windowClass) return ""
        var rewrites = {
            "com.mitchellh.ghostty": "Ghostty",
            "firefox": "Firefox",
            "google-chrome": "Chrome",
            "bruno": "Bruno",
            "slack": "Slack",
            "discord": "Discord",
            "Spotify": "Spotify",
            "org.kde.dolphin": "Dolphin",
            "thunar": "Thunar",
            "kitty": "Kitty",
            "obsidian": "Obsidian",
            "code": "VS Code",
            "thunderbird_thunderbird": "Thunderbird",
            "vesktop": "Discord",
            "vivaldi-stable": "Vivaldi",
        }
        return rewrites[windowClass] || windowClass
    }

    // sketchybar-app-font codepoint for the current app. These are direct
    // PUA characters (font rebuilt with useNameAsUnicode: false), so no
    // ligature/GSUB shaping is required - just a normal glyph lookup.
    // python3 extract_codepoints.py dist/sketchybar-app-font.ttf vivaldi
    property string iconGlyph: {
        if (!windowClass) return ""
        var icons = {
            "com.mitchellh.ghostty": "\uEAD9",
            "firefox": "\uEABF",
            "google-chrome": "\uEAE3",
            "bruno": "\uEA4D",
            "slack": "\uEC04",
            "discord": "\uEA9C",
            "vesktop": "\uEC51",
            "Spotify": "\uEC0F",
            "org.kde.dolphin": "\uEAA0",
            "kitty": "\uEB22",
            "obsidian": "\uEB81",
            "code": "\uEA72",
            "thunderbird_thunderbird": "\uEC34",
            "vivaldi-stable": "\uEC56",

            // no "thunar" entry: the font has no Linux file-manager icon
        }
        return icons[windowClass] || ""
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            id: iconText
            visible: iconGlyph.length > 0
            text: iconGlyph
            font.family: "sketchybar-app-font"
            font.pixelSize: 14 
            color: Config.moduleText
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: windowText
            anchors.verticalCenter: parent.verticalCenter
            text: displayText
            color: Config.moduleText
            font.pixelSize: Config.moduleFontSize
            font.family: Config.moduleFontFamily
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
