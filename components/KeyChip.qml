import QtQuick
import "root:/"

// A keybind or small status token, as in the overlay headers
Rectangle {
    property alias text: label.text

    implicitWidth: label.implicitWidth + 14
    implicitHeight: 22
    radius: 6
    color: Theme.surfaceHigh

    IslandLabel {
        id: label
        anchors.centerIn: parent
        kind: "meta"
        color: Theme.text
    }
}
