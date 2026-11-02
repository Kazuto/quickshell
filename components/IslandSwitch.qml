import QtQuick
import "root:/"

// The one primary control in a drill-down's header
Rectangle {
    id: root

    property bool checked: false
    property bool active: true
    signal toggled()

    implicitWidth: 40
    implicitHeight: 24
    radius: height / 2
    opacity: active ? 1 : 0.6
    color: checked ? Theme.accent : Theme.surfaceHigh

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    Rectangle {
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        width: 18
        height: 18
        radius: 9
        color: root.checked ? Theme.textOnAccent : Theme.textDim

        Behavior on x {
            NumberAnimation { duration: Config.animationDuration; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        enabled: root.active
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
