import QtQuick
import "root:/"

// The playing indicator: four accent bars, moving only while playing
Row {
    id: root

    property bool playing: true
    property int barWidth: 3
    property int maxHeight: 14

    spacing: 2
    height: maxHeight

    Repeater {
        model: [0.45, 1, 0.65, 0.85]

        delegate: Rectangle {
            required property int index
            required property var modelData

            property real level: modelData

            anchors.bottom: parent.bottom
            width: root.barWidth
            height: Math.max(2, root.maxHeight * level)
            radius: 1
            color: Theme.accent

            SequentialAnimation on level {
                running: root.playing
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 260 + index * 70; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 320 + index * 50; easing.type: Easing.InOutSine }
            }
        }
    }
}
