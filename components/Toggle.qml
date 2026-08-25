import QtQuick
import "root:/"

Rectangle {
    id: toggle

    property bool checked: false
    property color onColor: Theme.green
    property color offColor: Theme.surface2
    property color knobColor: Theme.text
    signal toggled(bool checked)

    width: 42
    height: 24
    radius: height / 2
    color: checked ? onColor : offColor

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: knob
        width: parent.height - 4
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: toggle.knobColor
        x: toggle.checked ? parent.width - width - 2 : 2

        Behavior on x {
            NumberAnimation { duration: Config.animationDuration; easing.type: Easing.OutCubic }
        }

        // Subtle scale bounce on press for extra feedback
        scale: mouseArea.pressed ? 0.9 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            toggle.checked = !toggle.checked
            toggle.toggled(toggle.checked)
        }
    }
}
