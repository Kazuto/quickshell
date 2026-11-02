import QtQuick
import "root:/"

// Selectable tile in quick access. Reaches its panel through the parent chain's
// `panel` id, since it only ever appears inside QuickPanel.
Rectangle {
    id: tile

    property var action: null
    property int actionIndex: 0

    readonly property bool selected: panel.selectedIndex === actionIndex

    radius: Config.controlRadius
    color: selected ? Theme.surfaceHigh : Theme.surfaceLow
    opacity: panel.matches(action) ? 1 : 0.35

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: panel.selectedIndex = tile.actionIndex
        onClicked: panel.run(tile.action)
    }
}
