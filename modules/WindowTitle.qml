import QtQuick
import Quickshell.Hyprland
import "root:/"
import "root:/js/AppIcons.js" as AppIcons

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

    // Display label + icon glyph both come from the shared AppIcons mapper
    // (also used by Tray.qml), so the same app always gets the same name
    // and icon wherever it shows up in the bar.
    property string displayText: windowClass ? (AppIcons.labelFor(windowClass) || windowClass) : ""

    property var iconInfo: windowClass ? AppIcons.glyphFor(windowClass) : null
    property string iconGlyph: iconInfo ? iconInfo.char : ""
    property string iconFont: iconInfo && iconInfo.font ? iconInfo.font : Config.moduleFontFamily

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            id: iconText
            visible: iconGlyph.length > 0
            text: iconGlyph
            font.family: iconFont
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
