import QtQuick
import "root:/"
import "root:/singletons"

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
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (AudioData.outputMuted) {
                    return Icon.volumeMuted + " Muted"
                } else {
                    return Icon.volume + " " + AudioData.outputVolume + "%"
                }
            }
            color: AudioData.outputMuted ? Theme.overlay0 : Theme.mauve
            font.pixelSize: Config.moduleFontSize
            font.family: Config.moduleFontFamily
        }

        // Microphone
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (AudioData.inputMuted) {
                    return Icon.microphoneMuted + " Muted"
                } else {
                    return Icon.microphone + " " + AudioData.inputVolume + "%"
                }
            }
            color: AudioData.inputMuted ? Theme.overlay0 : Theme.mauve
            font.pixelSize: Config.moduleFontSize
            font.family: Config.moduleFontFamily
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
