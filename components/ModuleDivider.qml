import QtQuick
import "root:/"

Rectangle {
    implicitWidth: 1
    implicitHeight: Config.barHeight * 0.45
    color: Theme.surface1
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
}
