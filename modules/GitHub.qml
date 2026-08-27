import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

Rectangle {
    implicitWidth: githubRow.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: githubMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    Row {
        id: githubRow
        anchors.centerIn: parent
        spacing: 6

        SvgIcon {
            name: "github"
            size: Config.moduleFontSize
            color: GitHubData.notificationCount > 0 ? Theme.red : Theme.subtext0
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: GitHubData.notificationCount
            color: GitHubData.notificationCount > 0 ? Theme.red : Theme.subtext0
            font.pixelSize: Config.moduleFontSize
            font.family: Config.moduleFontFamily
            anchors.verticalCenter: parent.verticalCenter
            visible: GitHubData.notificationCount > 0
        }
    }

    MouseArea {
        id: githubMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { AppState.lastClickX = mapToItem(null, width / 2, 0).x; AppState.toggleGitHubOverlay() }
    }
}
