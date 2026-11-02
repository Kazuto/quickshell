import QtQuick
import "root:/"
import "root:/singletons"
import "root:/components"

// A: click the core while playing
PanelFrame {
    id: panel

    headerLeft: [
        EqBars {
            playing: MediaData.isPlaying
            anchors.verticalCenter: parent.verticalCenter
        },
        IslandLabel {
            text: "Now playing"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        IslandLabel {
            text: MediaData.identity
            kind: "meta"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    Row {
        width: parent.width
        spacing: 16

        Rectangle {
            width: 96
            height: 96
            radius: Config.controlRadius
            color: Theme.surfaceHigh

            SvgIcon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                name: "disc"
                size: 28
                color: Theme.textDim
            }

            RoundedImage {
                id: art
                anchors.fill: parent
                source: MediaData.artUrl
                radius: parent.radius
            }
        }

        Column {
            width: parent.width - 96 - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            IslandLabel {
                width: parent.width
                text: MediaData.title || "Nothing playing"
                kind: "title"
            }

            IslandLabel {
                width: parent.width
                visible: text !== ""
                text: MediaData.artist
                color: Theme.textDim
            }

            IslandLabel {
                width: parent.width
                visible: text !== ""
                text: MediaData.album
                color: Theme.textDim
            }
        }
    }

    Column {
        width: parent.width
        spacing: 4

        BarSlider {
            width: parent.width
            thickness: 4
            interactive: MediaData.canSeek
            value: MediaData.length > 0 ? MediaData.position / MediaData.length * 100 : 0
            onMoved: value => MediaData.seekToFraction(value / 100)
        }

        Item {
            width: parent.width
            height: 14

            IslandLabel {
                anchors.verticalCenter: parent.verticalCenter
                text: MediaData.formatSeconds(MediaData.position)
                kind: "meta"
            }

            IslandLabel {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: MediaData.formatSeconds(MediaData.length)
                kind: "meta"
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        IslandButton {
            iconName: "skip-back"
            anchors.verticalCenter: parent.verticalCenter
            onClicked: MediaData.previous()
        }

        IslandButton {
            implicitHeight: 56
            iconSize: 20
            variant: "accent"
            iconName: MediaData.isPlaying ? "pause" : "play"
            anchors.verticalCenter: parent.verticalCenter
            onClicked: MediaData.togglePlaying()
        }

        IslandButton {
            iconName: "skip-forward"
            anchors.verticalCenter: parent.verticalCenter
            onClicked: MediaData.next()
        }
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Space) MediaData.togglePlaying()
        else if (event.key === Qt.Key_Left) MediaData.previous()
        else if (event.key === Qt.Key_Right) MediaData.next()
        else return
        event.accepted = true
    }
}
