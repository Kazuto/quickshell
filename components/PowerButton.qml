import QtQuick
import "root:/"
import "root:/components"

Item {
    id: powerButton

    property string label: ""
    property string keyHint: ""
    property string icon: ""
    property color accentColor: Theme.text

    signal activated()

    width: 140
    height: 140

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: powerButton.activated()
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 16
        color: mouseArea.containsMouse ? Config.alpha(powerButton.accentColor, 0.15) : Theme.surface0
        border.color: mouseArea.containsMouse ? powerButton.accentColor : Theme.surface1
        border.width: 2

        Behavior on color {
            ColorAnimation { duration: Config.animationDuration }
        }
        Behavior on border.color {
            ColorAnimation { duration: Config.animationDuration }
        }

        Column {
            anchors.centerIn: parent
            spacing: 12

            SvgIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: powerButton.icon
                size: 36
                color: powerButton.accentColor
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: powerButton.label
                color: mouseArea.containsMouse ? Theme.text : Theme.subtext1
                font.pixelSize: 14
                font.bold: true
                font.family: Config.moduleFontFamily

                Behavior on color {
                    ColorAnimation { duration: Config.animationDuration }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "[" + powerButton.keyHint + "]"
                color: Theme.overlay0
                font.pixelSize: 11
                font.family: Config.moduleFontFamily
            }
        }
    }
}
