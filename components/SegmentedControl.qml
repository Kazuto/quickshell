import QtQuick
import "root:/"

Rectangle {
    id: root

    property var options: []       // labels
    property int currentIndex: 0
    property bool active: true
    property int inset: 4
    signal activated(int index)

    implicitHeight: 44
    radius: Config.controlRadius
    color: Theme.surfaceLow
    opacity: active ? 1 : 0.6

    Row {
        anchors.fill: parent
        anchors.margins: root.inset

        Repeater {
            model: root.options

            delegate: Rectangle {
                required property int index
                required property var modelData

                readonly property bool selected: index === root.currentIndex

                width: parent.width / root.options.length
                height: parent.height
                radius: Config.controlRadius - root.inset
                color: selected ? Theme.surfaceTop : "transparent"

                Behavior on color {
                    ColorAnimation { duration: Config.animationDuration }
                }

                IslandLabel {
                    anchors.centerIn: parent
                    text: modelData
                    kind: selected ? "island" : "body"
                    color: selected ? Theme.text : Theme.textDim
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.active
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activated(index)
                }
            }
        }
    }
}
