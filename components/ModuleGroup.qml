import QtQuick
import "root:/"

Rectangle {
    default property alias items: row.data

    implicitWidth: row.implicitWidth + 8
    implicitHeight: Config.barHeight
    color: Config.moduleBackground
    radius: Config.moduleRadius

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0
    }
}
