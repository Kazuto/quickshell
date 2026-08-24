import QtQuick
import Quickshell.Io
import "root:/"

Rectangle {
    implicitWidth: spotifyText.implicitWidth + Config.moduleHorizontalPadding
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

    // Get Spotify metadata
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
                // Spotify not running or no player found
                artist = ""
                title = ""
                status = ""
            }
        }
    }

    // Update every second
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            metadataProcess.running = false
            metadataProcess.running = true
        }
    }

    Text {
        id: spotifyText
        anchors.centerIn: parent
        text: {
            if (!hasSpotify) return Icon.spotify + " Not running"

            var songText = artist && title ? artist + " - " + title : (title || artist || "Unknown")

            return Icon.spotify + " " + songText
        }
        color: isPlaying ? Theme.green : Theme.overlay0
        font.pixelSize: Config.moduleFontSize
        font.family: Config.moduleFontFamily
        elide: Text.ElideRight
        maximumLineCount: 1
    }

    MouseArea {
        id: spotifyMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            AppState.toggleSpotifyOverlay()
        }
    }
}
