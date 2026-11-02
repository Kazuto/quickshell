pragma Singleton

import QtQuick
import Quickshell
import "root:/singletons"

Singleton {
    // Island v1 tokens
    property color desk: "#0b0c12"
    property color island: "#0f1017"
    property color surfaceLow: "#1a1c27"
    property color surfaceHigh: "#242737"
    property color surfaceTop: "#33364a"
    property color text: "#e6e8f2"
    property color textDim: "#a0a6bd"
    property color textFaint: "#5f6479"
    property color stroke: Qt.rgba(1, 1, 1, 0.08)
    property color textOnAccent: "#0f1017"

    readonly property color sakura: "#f2a7bd"
    // Follows the wallpaper when "Derive accent from wallpaper" is on
    property color accent: WallpaperData.accentOverride !== "" ? WallpaperData.accentOverride : sakura
    property color accentSky: "#a8c5ee"
    property color rec: "#ff7b86"
    property color warn: "#f5c27a"

    // Palette names the older overlays still read, mapped onto the tokens above
    property color base: island
    property color mantle: desk
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
