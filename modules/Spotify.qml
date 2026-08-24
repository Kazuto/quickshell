import QtQuick
import Quickshell.Io
import "root:/"
import "root:/components"

Rectangle {
    implicitWidth: spotifyRow.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: spotifyMouseArea.containsMouse ? Config.moduleHoverBackground : Config.moduleBackground
    radius: Config.moduleRadius

    property string artist: ""
    property string title: ""
    property string status: ""
    property bool isPlaying: status === "Playing"
    property bool hasSpotify: artist !== "" || title !== ""

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    Process {
        id: metadataProcess
        running: true
        command: ["playerctl", "-p", "spotify", "metadata", "--format", "{{artist}}|||{{title}}|||{{status}}"]

        stdout: SplitParser {
            onRead: data => {
                var parts = data.split("|||")
                if (parts.length >= 3) {
                    artist = parts[0] || ""
                    title = parts[1] || ""
                    status = parts[2] || ""
                }
            }
        }

        stderr: SplitParser {
            onRead: data => {
                artist = ""
                title = ""
                status = ""
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            metadataProcess.running = false
            metadataProcess.running = true
        }
    }

    Row {
        id: spotifyRow
        anchors.centerIn: parent
        spacing: 6

        SvgIcon {
            name: "spotify"
            size: Config.moduleFontSize
            color: isPlaying ? Theme.green : Theme.overlay0
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: spotifyText
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (!hasSpotify) return "Not running"
                return artist && title ? artist + " - " + title : (title || artist || "Unknown")
            }
            color: isPlaying ? Theme.green : Theme.overlay0
            font.pixelSize: Config.moduleFontSize
            font.family: Config.moduleFontFamily
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    MouseArea {
        id: spotifyMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleSpotifyOverlay()
    }
}
