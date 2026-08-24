import QtQuick
import "root:/"

Rectangle {
    id: ghostButton

    property string text: ""
    property string icon: ""
    property color iconColor: Theme.text
    property color textColor: Theme.text
    property int iconSize: 14
    property int fontSize: 14
    property bool highlighted: false
    property bool enabled: true
    signal clicked()

    width: 100
    height: 45

    radius: 8
    color: highlighted ? Theme.surface1 : (mouseArea.containsMouse ? Theme.surface0 : "transparent")
    opacity: enabled ? 1.0 : 0.5
    border.color: highlighted ? Theme.blue : "transparent"
    border.width: highlighted ? 2 : 0

    Behavior on border.color {
        ColorAnimation { duration: Config.animationDuration }
    }

    Row {
        anchors.centerIn: parent
        spacing: ghostButton.text.length > 0 && ghostButton.icon.length > 0 ? 10 : 0

        Text {
            text: ghostButton.icon
            color: ghostButton.iconColor
            font.pixelSize: ghostButton.iconSize
            font.family: Config.moduleFontFamily
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
            visible: ghostButton.icon.length > 0
        }

        Text {
            text: ghostButton.text
            color: ghostButton.textColor
            font.pixelSize: ghostButton.fontSize
            font.family: Config.moduleFontFamily
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
            visible: ghostButton.text.length > 0
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: ghostButton.enabled
        cursorShape: ghostButton.enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
        onClicked: ghostButton.clicked()
    }
}
