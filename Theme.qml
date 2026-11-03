pragma Singleton

import QtQuick
import Quickshell
import "root:/singletons"

Singleton {
    // Island v1 tokens, on Catppuccin Mocha backgrounds to match the other apps
    property color desk: "#11111b"
    property color island: "#1e1e2e"
    property color surfaceLow: "#313244"
    property color surfaceHigh: "#45475a"
    property color surfaceTop: "#585b70"
    property color text: "#e6e8f2"
    property color textDim: "#a0a6bd"
    property color textFaint: "#6c7086"
    property color stroke: Qt.rgba(1, 1, 1, 0.08)
    property color textOnAccent: "#11111b"

    readonly property color sakura: "#f2a7bd"
    // Follows the wallpaper unless "Derive accent from wallpaper" is off
    property color accent: WallpaperData.accentOverride !== "" ? WallpaperData.accentOverride : sakura
    property color accentSky: "#a8c5ee"
    property color rec: "#ff7b86"
    property color warn: "#f5c27a"

    // Palette names the older overlays still read, mapped onto the tokens above
    property color base: island
    property color mantle: "#181825"
    property color crust: desk

    property color surface0: surfaceLow
    property color surface1: surfaceHigh
    property color surface2: surfaceTop

    property color overlay0: textFaint
    property color overlay1: "#7d8298"
    property color overlay2: "#8f95ab"

    property color subtext1: "#c3c7d9"
    property color subtext0: textDim

    // Accent colors
    property color rosewater: accent
    property color flamingo: accent
    property color pink: accent
    property color mauve: accent
    property color red: rec
    property color maroon: rec
    property color peach: accent
    property color yellow: warn
    property color green: "#a9dcb4"
    property color teal: accentSky
    property color sky: accentSky
    property color sapphire: accentSky
    property color blue: accentSky
    property color lavender: accentSky
}
