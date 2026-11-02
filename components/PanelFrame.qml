import QtQuick
import "root:/"

// A panel is the island grown taller: same anchor, same header row, then the
// body. Padding is 8 / 20 / 20 from the design's geometry tokens.
Item {
    id: frame

    property alias headerLeft: leftRow.data
    property alias headerRight: rightRow.data
    default property alias content: body.data
    property alias spacing: body.spacing
    property int panelWidth: Config.panelWidth
    property int bodyInset: Config.panelPadSide
    property int bodyTopGap: 16
    // Panel the back button returns to, for details opened from another panel
    property string backTo: ""

    readonly property int cornerRadius: Config.panelRadius
    readonly property int headerWidth: panelWidth - 2 * Config.panelPadSide
    readonly property int bodyWidth: panelWidth - 2 * bodyInset

    implicitWidth: panelWidth
    implicitHeight: body.y + body.implicitHeight + Config.panelPadBottom

    Row {
        x: Config.panelPadSide
        y: Config.panelPadTop
        height: Config.panelHeaderHeight
        spacing: 10

        Rectangle {
            visible: frame.backTo !== ""
            width: 28
            height: 28
            radius: 14
            color: backMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceLow
            anchors.verticalCenter: parent.verticalCenter

            SvgIcon {
                anchors.centerIn: parent
                name: "caret-left"
                size: 12
                color: Theme.textDim
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: AppState.openPanel(frame.backTo)
            }
        }

        Row {
            id: leftRow
            height: parent.height
            spacing: 8
        }
    }

    Row {
        id: rightRow
        x: frame.panelWidth - Config.panelPadSide - width
        y: Config.panelPadTop
        height: Config.panelHeaderHeight
        spacing: 8
    }

    Rectangle {
        id: divider
        x: Config.panelPadSide
        y: Config.panelPadTop + Config.panelHeaderHeight + 8
        width: frame.headerWidth
        height: 1
        color: Theme.stroke
    }

    Column {
        id: body
        x: frame.bodyInset
        y: divider.y + 1 + frame.bodyTopGap
        width: frame.bodyWidth
        spacing: 16
    }
}
