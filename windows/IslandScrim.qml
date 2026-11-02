import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"

// Sits below the island while a panel is open: catches the click outside that
// closes it and, for keybind overlays, dims the rest of the screen to 40%.
PanelWindow {
    id: scrim

    required property var modelData

    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: AppState.islandPanel !== "" && AppState.islandPanelOutput === modelData.name

    WlrLayershell.namespace: "quickshell-scrim"
    WlrLayershell.layer: WlrLayer.Overlay
    // While any surface holds exclusive focus, Hyprland routes the pointer only to
    // exclusive surfaces, so the catcher has to be one too or it never sees a click.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Rectangle {
        anchors.fill: parent
        color: AppState.islandPanelDims ? Config.alpha(Theme.desk, 0.6) : "transparent"

        Behavior on color {
            ColorAnimation { duration: Config.morphOpenMs }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: AppState.closePanel()
        }
    }
}
