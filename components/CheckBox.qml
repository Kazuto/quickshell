import QtQuick
import "root:/"

Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    implicitWidth: 16
    implicitHeight: 16
    radius: 4
    color: checked ? Theme.accent : "transparent"
    border.width: checked ? 0 : 1
    border.color: Theme.textFaint

    SvgIcon {
        anchors.centerIn: parent
        visible: root.checked
        name: "check"
        size: 12
        color: Theme.textOnAccent
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -8
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
