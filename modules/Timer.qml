import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

Rectangle {
    implicitWidth: timerRow.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: timerMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    Row {
        id: timerRow
        anchors.centerIn: parent
        spacing: 6

        SvgIcon {
            name: "timer"
            size: Config.moduleFontSize
            color: TimerData.remainingSeconds < 0 ? Theme.red : (TimerData.running ? Theme.yellow : Theme.subtext0)
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: TimerData.displayTime
            color: TimerData.remainingSeconds < 0 ? Theme.red : (TimerData.running ? Theme.yellow : Theme.subtext0)
            font.pixelSize: Config.moduleFontSize
            font.family: Config.moduleFontFamily
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: timerMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { AppState.lastClickX = mapToItem(null, width / 2, 0).x; AppState.toggleTimerOverlay() }
    }
}
