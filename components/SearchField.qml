import QtQuick
import "root:/"

// Header input of the keybind overlays. The panel owns the keys and the text;
// this only draws them, the same way the older search overlays worked.
Item {
    id: root

    property string text: ""
    property string placeholder: ""
    property string iconName: "search"

    implicitHeight: Config.panelHeaderHeight

    SvgIcon {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        name: root.iconName
        size: 16
        color: Theme.textDim
    }

    IslandLabel {
        id: value
        anchors.verticalCenter: parent.verticalCenter
        x: icon.width + 12
        width: Math.min(implicitWidth, root.width - x - 6)
        text: root.text !== "" ? root.text : root.placeholder
        color: root.text !== "" ? Theme.text : Theme.textDim
        font.pixelSize: 14
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: root.text !== "" ? value.x + value.width + 1 : value.x - 3
        width: 2
        height: 16
        radius: 1
        color: Theme.accent
        visible: blink.cursorVisible
    }

    BlinkCursor {
        id: blink
        active: root.visible
    }
}
