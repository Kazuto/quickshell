import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"

PanelWindow {
    id: root

    anchors { top: true; right: true; bottom: true; left: true }

    color: "transparent"
    visible: AppState.trayTooltipVisible && AppState.trayTooltipText.length > 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // Only the small pill itself accepts input (none, in this case — it's
    // purely visual) so hovering the tray icon underneath, which lives in
    // the bar's own separate window, keeps working normally.
    mask: Region { item: pill }

    Rectangle {
        id: pill
        anchors {
            top: parent.top
            topMargin: Config.barHeight + Config.barMarginTop + Config.tooltipMargin
        }
        // Use Screen.width rather than root.width — root's own geometry
        // briefly reads 0 on the very first frame before the compositor
        // assigns the surface its real size.
        x: Math.min(Math.max(AppState.trayTooltipX - width / 2, 6), Screen.width - width - 6)

        width: tooltipText.implicitWidth + Config.tooltipPadding * 2
        height: tooltipText.implicitHeight + Config.tooltipPadding
        radius: Config.tooltipRadius
        color: Theme.mantle
        border.color: Theme.surface0
        border.width: 1

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: AppState.trayTooltipText
            color: Theme.text
            font.pixelSize: Config.tooltipFontSize
            font.family: Config.moduleFontFamily
        }
    }
}
