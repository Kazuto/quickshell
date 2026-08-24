import QtQuick
import "root:/"
import "root:/singletons"

Rectangle {
    implicitWidth: githubText.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: githubMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    Text {
        id: githubText
        anchors.centerIn: parent
        text: Icon.github + " " + GitHubData.notificationCount
        color: GitHubData.notificationCount > 0 ? Theme.red : Theme.text
        font.pixelSize: Config.moduleFontSize
        font.family: Config.moduleFontFamily
    }

    MouseArea {
        id: githubMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleGitHubOverlay()
    }
}
