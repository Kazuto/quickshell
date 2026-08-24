import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

Rectangle {
    implicitWidth: audioRow.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: audioMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    Row {
        id: audioRow
        anchors.centerIn: parent
        spacing: 8

        // Volume
        Row {
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter

            SvgIcon {
                name: AudioData.outputMuted ? "volume-muted" : "volume"
                size: Config.moduleFontSize
                color: AudioData.outputMuted ? Theme.overlay0 : Theme.mauve
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: AudioData.outputMuted ? "Muted" : AudioData.outputVolume + "%"
                color: AudioData.outputMuted ? Theme.overlay0 : Theme.mauve
                font.pixelSize: Config.moduleFontSize
                font.family: Config.moduleFontFamily
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Microphone
        Row {
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter

            SvgIcon {
                name: AudioData.inputMuted ? "microphone-muted" : "microphone"
                size: Config.moduleFontSize
                color: AudioData.inputMuted ? Theme.overlay0 : Theme.mauve
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: AudioData.inputMuted ? "Muted" : AudioData.inputVolume + "%"
                color: AudioData.inputMuted ? Theme.overlay0 : Theme.mauve
                font.pixelSize: Config.moduleFontSize
                font.family: Config.moduleFontFamily
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    MouseArea {
        id: audioMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleAudioOverlay()
    }
}
