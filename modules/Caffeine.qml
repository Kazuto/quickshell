import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

Rectangle {
    implicitWidth: Config.barHeight
    implicitHeight: Config.barHeight
    color: caffeineMouseArea.containsMouse
        ? Config.moduleHoverBackground
        : (CaffeineData.active ? Config.alpha(Theme.yellow, 0.2) : Config.moduleBackground)
    radius: Config.moduleRadius

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    SvgIcon {
        anchors.centerIn: parent
        name: "coffee"
        size: Config.moduleFontSize
        color: CaffeineData.active ? Theme.yellow : Theme.overlay1
    }

    MouseArea {
        id: caffeineMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: CaffeineData.toggle()
    }
}
