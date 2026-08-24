import QtQuick
import "root:/"

Rectangle {
    implicitWidth: clockText.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: clockMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        text: Icon.calendar + " " + Qt.formatDateTime(new Date(), Config.clockFormat)
        color: Theme.blue
        font.pixelSize: Config.moduleFontSize
        font.family: Config.moduleFontFamily
    }

    Timer {
        interval: Config.clockShowSeconds ? 1000 : 60000
        running: true
        repeat: true
        onTriggered: clockText.text = Qt.formatDateTime(new Date(), Config.clockFormat)
    }

    MouseArea {
        id: clockMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleCalendarOverlay()
    }
}
