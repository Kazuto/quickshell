import QtQuick
import "root:/"
import "root:/singletons"

Rectangle {
    implicitWidth: timerText.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: timerMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    Text {
        id: timerText
        anchors.centerIn: parent
        text: Icon.clock + " " + TimerData.displayTime
        color: TimerData.remainingSeconds < 0 ? Theme.red : (TimerData.running ? Theme.yellow : Theme.text)
        font.pixelSize: Config.moduleFontSize
        font.family: Config.moduleFontFamily
    }

    MouseArea {
        id: timerMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleTimerOverlay()
    }
}
