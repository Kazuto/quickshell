import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

Rectangle {
    implicitWidth: Config.barHeight
    implicitHeight: Config.barHeight
    color: ollamaMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    SvgIcon {
        anchors.centerIn: parent
        name: "ollama"
        size: Config.moduleFontSize
        color: OllamaData.isRunning ? Theme.green : Theme.overlay0
    }

    MouseArea {
        id: ollamaMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleOllamaOverlay()
    }
}
