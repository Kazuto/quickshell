import QtQuick
import "root:/"

// Rounded tab above a list. Unselected ones recede so the selected one reads first.
Rectangle {
    id: chip

    property string label: ""
    property bool selected: false
    signal clicked()

    implicitWidth: text.implicitWidth + 24
    implicitHeight: 32
    radius: height / 2
    color: selected ? Theme.surfaceTop : mouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceLow

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    IslandLabel {
        id: text
        anchors.centerIn: parent
        text: chip.label
        kind: chip.selected ? "island" : "body"
        color: chip.selected ? Theme.text : Theme.textDim
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
