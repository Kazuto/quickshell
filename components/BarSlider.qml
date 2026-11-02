import QtQuick
import "root:/"

// Progress bar that doubles as a slider when interactive. Values are 0–100.
Item {
    id: root

    property real value: 0
    property color fillColor: Theme.accent
    property color trackColor: Theme.surfaceHigh
    property int thickness: 8
    property bool interactive: true
    // Follows the pointer during a drag, so a model update can't pull it away
    property real dragValue: -1
    readonly property real shownValue: dragValue >= 0 ? dragValue : value
    signal moved(real value)
    signal committed(real value)

    implicitHeight: interactive ? Math.max(thickness, 20) : thickness

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.thickness
        radius: root.thickness / 2
        color: root.trackColor

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.shownValue / 100))
            height: parent.height
            radius: parent.radius
            color: root.fillColor

            Behavior on width {
                NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor

        function report(x) {
            root.dragValue = Math.max(0, Math.min(1, x / width)) * 100
            root.moved(root.dragValue)
        }

        onPressed: mouse => report(mouse.x)
        onPositionChanged: mouse => { if (pressed) report(mouse.x) }
        onReleased: {
            var lastValue = root.dragValue
            root.dragValue = -1
            root.committed(lastValue)
        }
    }
}
