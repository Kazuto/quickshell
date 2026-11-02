import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

// State 03: a notification overlays the core for its hold, then hands it back
Item {
    id: root

    required property var screen

    readonly property var notification: IslandData.notification
    readonly property int cornerRadius: Config.islandTransientHeight / 2
    readonly property int textWidth: Math.max(appLabel.implicitWidth, summaryLabel.implicitWidth)

    implicitWidth: Math.max(340, Math.min(520, 10 + 36 + 12 + textWidth + 16 + 24 + 20))
    implicitHeight: Config.islandTransientHeight

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.openPanel("notifications", root.screen.name)
    }

    IconDisc {
        id: disc
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        diameter: 36
        iconSize: 16
        iconName: "image"
        imageSource: root.notification ? root.notification.icon : ""
    }

    Column {
        anchors.left: disc.right
        anchors.leftMargin: 12
        anchors.right: age.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        IslandLabel {
            id: appLabel
            width: parent.width
            text: root.notification ? root.notification.app : ""
            kind: "meta"
        }

        IslandLabel {
            id: summaryLabel
            width: parent.width
            text: root.notification ? root.notification.summary : ""
            kind: "island"
        }
    }

    IslandLabel {
        id: age
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        text: "now"
        kind: "meta"
    }
}
