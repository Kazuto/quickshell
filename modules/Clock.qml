import QtQuick
import "root:/"
import "root:/components"

Rectangle {
    id: clockRect
    implicitWidth: clockRow.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: clockMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 6

        SvgIcon {
            name: "calendar"
            size: Config.moduleFontSize
            color: Theme.subtext0
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: clockText
            text: Qt.formatDateTime(new Date(), Config.clockFormat).trim()
            color: Theme.subtext0
            font.pixelSize: Config.moduleFontSize
            font.family: Config.moduleFontFamily
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Timer {
        interval: Config.clockShowSeconds ? 1000 : 60000
        running: true
        repeat: true
        onTriggered: clockText.text = Qt.formatDateTime(new Date(), Config.clockFormat).trim()
    }

    MouseArea {
        id: clockMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleCalendarOverlay()
    }
}
