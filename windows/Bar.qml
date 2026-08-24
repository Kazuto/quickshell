import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"

PanelWindow {
    id: bar

    property alias leftItems: container_left.data
    property alias centerItems: container_center.data
    property alias rightItems: container_right.data

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Config.barHeight
    margins {
        top: Config.barMarginTop
        left: Config.barMarginSide
        right: Config.barMarginSide
        bottom: 0
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: Config.barHeight

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 0
        border.width: 0

        // Left section
        Row {
            id: container_left
            spacing: Config.moduleSpacing
            height: parent.height

            anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
        }

        // Center section
        Row {
            id: container_center
            spacing: Config.moduleSpacing
            height: parent.height

            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
        }

        // Right section
        Row {
            id: container_right
            spacing: Config.moduleSpacing
            height: parent.height

            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
        }
    }
}
