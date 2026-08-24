import QtQuick
import "root:/"
import "root:/singletons"

Rectangle {
    implicitWidth: ollamaText.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: ollamaMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    Text {
        id: ollamaText
        anchors.centerIn: parent
        text: Icon.ollama
        color: OllamaData.isRunning ? Theme.green : Theme.overlay0
        font.pixelSize: Config.moduleFontSize
        font.family: Config.moduleFontFamily
    }

    MouseArea {
        id: ollamaMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleOllamaOverlay()
    }
}
