import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

// State 08: outputs without focus only keep workspaces and the time
Item {
    id: root

    required property var screen

    readonly property int cornerRadius: Config.islandCompactHeight / 2

    implicitWidth: row.implicitWidth + 2 * 12
    implicitHeight: Config.islandCompactHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        WorkspaceDots {
            screen: root.screen
            muted: true
            dotSize: 5
            activeWidth: 14
            cellHeight: Config.islandCompactHeight
            anchors.verticalCenter: parent.verticalCenter
        }

        IslandLabel {
            text: IslandData.clockText
            kind: "meta"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
