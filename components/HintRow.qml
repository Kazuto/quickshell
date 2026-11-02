import QtQuick
import "root:/"

// Footer of the keybind overlays: what the keys do, with Esc pinned right
Item {
    id: root

    property var hints: []
    property string trailing: "Esc close"

    implicitHeight: 18

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16

        Repeater {
            model: root.hints
            delegate: IslandLabel {
                required property var modelData
                text: modelData
                kind: "meta"
            }
        }
    }

    IslandLabel {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.trailing
        kind: "meta"
    }
}
