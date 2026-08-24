import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "root:/"

PanelWindow {
    id: spotifyOverlay

    // Fill screen for positioning, but content will be centered
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: AppState.spotifyOverlayVisible = false
        z: -1
    }

    // Get Spotify metadata
    property string artist: ""
    property string title: ""
    property string album: ""
    property string artUrl: ""
    property string status: "stopped"
    property int position: 0
    property int length: 0

    // Update Spotify info
    Process {
        id: metadataProcess
        running: spotifyOverlay.visible
        command: ["playerctl", "metadata", "--player=spotify", "--format",
                  "{{artist}}|||{{title}}|||{{album}}|||{{mpris:artUrl}}|||{{status}}|||{{position}}|||{{mpris:length}}"]

        stdout: SplitParser {
            onRead: data => {
                var parts = data.split("|||")
                if (parts.length >= 7) {
                    spotifyOverlay.artist = parts[0] || "Unknown Artist"
                    spotifyOverlay.title = parts[1] || "Unknown Title"
                    spotifyOverlay.album = parts[2] || "Unknown Album"
                    spotifyOverlay.artUrl = parts[3] || ""
                    spotifyOverlay.status = parts[4] || "stopped"
                    spotifyOverlay.position = parseInt(parts[5]) || 0
                    spotifyOverlay.length = parseInt(parts[6]) || 0
                }
            }
        }
    }

    // Refresh metadata every second when visible
    Timer {
        interval: 1000
        running: spotifyOverlay.visible
        repeat: true
        onTriggered: {
            metadataProcess.running = false
            metadataProcess.running = true
        }
    }

    // Arrow pointer at the top (connects to Waybar)
    Canvas {
        id: arrow
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: spotifyOverlay.visible ? 6 : 0
        }
        width: 20
        height: 10
        opacity: spotifyOverlay.visible ? 1.0 : 0.0

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            // Draw triangle pointing up
            ctx.fillStyle = Theme.green  // Match border color
            ctx.beginPath()
            ctx.moveTo(10, 0)  // Top point
            ctx.lineTo(0, 10)  // Bottom left
            ctx.lineTo(20, 10) // Bottom right
            ctx.closePath()
            ctx.fill()
        }

        Behavior on anchors.topMargin {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
    }

    // Main container - positioned at top-center
    Rectangle {
        id: container
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: spotifyOverlay.visible ? 12 : 5  // Almost touching Waybar
        }
        width: 480
        height: 320
        radius: Config.overlayRadius
        opacity: spotifyOverlay.visible ? 1.0 : 0.0  // Fade animation

        color: Config.alpha(Theme.base, 0.95)
        border.color: Config.alpha(Theme.green, 0.95)
        border.width: 1

        // Subtle shadow effect
        layer.enabled: true
        layer.effect: ShaderEffect {
            property color shadowColor: "#40000000"
        }

        // Slide down animation
        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        // Fade animation
        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // Top section: Album art (left) + Track info (right)
            RowLayout {
                Layout.fillWidth: true
                spacing: 15

                // Square album art on the left (with rounded corners via clipping)
                Item {
                    Layout.preferredWidth: 140
                    Layout.preferredHeight: 140

                    Rectangle {
                        id: artBackground
                        anchors.fill: parent
                        radius: 8
                        color: "#40000000"
                        clip: true

                        Image {
                            id: albumArt
                            anchors.fill: parent
                            source: spotifyOverlay.artUrl.replace("file://", "")
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                        }
                    }

                    // Border overlay
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        radius: 8
                        border.color: "#30FFFFFF"
                        border.width: 1
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "🎵"
                        font.pixelSize: 48
                        color: "#60FFFFFF"
                        visible: !albumArt.source || albumArt.status !== Image.Ready
                    }
                }

                // Track info on the right
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    Item { Layout.fillHeight: true }  // Spacer

                    Text {
                        Layout.fillWidth: true
                        text: spotifyOverlay.title
                        font.pixelSize: 18
                        font.bold: true
                        color: "white"
                        elide: Text.ElideRight
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                    }

                    Text {
                        Layout.fillWidth: true
                        text: spotifyOverlay.artist
                        font.pixelSize: 14
                        color: "#cdd6f4"
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: spotifyOverlay.album
                        font.pixelSize: 12
                        color: "#9399b2"
                        elide: Text.ElideRight
                    }

                    Item { Layout.fillHeight: true }  // Spacer
                }
            }

            // Progress bar (clickable for scrubbing)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: formatTime(spotifyOverlay.position)
                    font.pixelSize: 12
                    color: "#9399b2"
                }

                Rectangle {
                    id: progressBar
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: "#40313244"

                    Rectangle {
                        width: spotifyOverlay.length > 0 ?
                               parent.width * (spotifyOverlay.position / spotifyOverlay.length) : 0
                        height: parent.height
                        radius: parent.radius
                        color: Theme.green
                    }

                    // Click to scrub
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            var clickPosition = mouse.x / progressBar.width
                            var seekPosition = clickPosition * spotifyOverlay.length
                            var seekSeconds = Math.floor(seekPosition / 1000000)

                            var proc = Qt.createQmlObject(
                                'import Quickshell.Io; Process { command: ["playerctl", "--player=spotify", "position", "' + seekSeconds + '"]; running: true }',
                                spotifyOverlay
                            )
                        }
                    }
                }

                Text {
                    text: formatTime(spotifyOverlay.length)
                    font.pixelSize: 12
                    color: "#9399b2"
                }
            }

            // Control buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                // Previous button
                Rectangle {
                    width: 60
                    height: 60
                    radius: 30
                    color: Config.alpha(Theme.surface0, 0.25)
                    border.color: Config.alpha(Theme.text, 0.4)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        font.pixelSize: 24
                        font.family: Config.moduleFontFamily
                        color: Theme.text
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            parent.color = "#60313244"
                            var proc = Qt.createQmlObject(
                                'import Quickshell.Io; Process { command: ["playerctl", "--player=spotify", "previous"]; running: true }',
                                spotifyOverlay
                            )
                        }
                        onPressed: parent.color = Config.alpha(Theme.surface0, 0.5)
                        onReleased: parent.color = Config.alpha(Theme.surface0, 0.25)
                    }
                }

                // Play/Pause button
                Rectangle {
                    width: 60
                    height: 60
                    radius: 30
                    color: Theme.green
                    border.color: Theme.green
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: spotifyOverlay.status === "Playing" ? "󰏤" : "󰐊"
                        font.pixelSize: 24
                        font.family: Config.moduleFontFamily
                        color: Theme.base
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var proc = Qt.createQmlObject(
                                'import Quickshell.Io; Process { command: ["playerctl", "--player=spotify", "play-pause"]; running: true }',
                                spotifyOverlay
                            )
                        }
                        onPressed: parent.color = Qt.lighter(Theme.green, 1.2)
                        onReleased: parent.color = Theme.green
                    }
                }

                // Next button
                Rectangle {
                    width: 60
                    height: 60
                    radius: 30
                    color: Config.alpha(Theme.surface0, 0.25)
                    border.color: Config.alpha(Theme.text, 0.4)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        font.pixelSize: 24
                        font.family: Config.moduleFontFamily
                        color: Theme.text
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var proc = Qt.createQmlObject(
                                'import Quickshell.Io; Process { command: ["playerctl", "--player=spotify", "next"]; running: true }',
                                spotifyOverlay
                            )
                        }
                        onPressed: parent.color = Config.alpha(Theme.surface0, 0.5)
                        onReleased: parent.color = Config.alpha(Theme.surface0, 0.25)
                    }
                }
            }
        }
    }

    // Format microseconds to mm:ss
    function formatTime(microseconds) {
        var seconds = Math.floor(microseconds / 1000000)
        var mins = Math.floor(seconds / 60)
        var secs = seconds % 60
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

}
