pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "root:/"

Singleton {
    id: root

    property var lastPlaying: null

    // Whichever player started playing last; otherwise the last one that played,
    // so the panel keeps its controls.
    readonly property var player: {
        var list = Mpris.players.values
        var playing = null
        var known = null
        for (var i = 0; i < list.length; i++) {
            if (list[i] === lastPlaying) known = list[i]
            if (list[i].isPlaying && (!playing || list[i] === lastPlaying)) playing = list[i]
        }
        return playing || known || (list.length > 0 ? list[0] : null)
    }

    readonly property bool isPlaying: player ? player.isPlaying : false
    readonly property string title: player ? (player.trackTitle || "") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string album: player ? (player.trackAlbum || "") : ""
    readonly property string artUrl: player ? (player.trackArtUrl || "") : ""
    readonly property string identity: player ? (player.identity || "").toLowerCase() : ""
    readonly property real position: player && player.positionSupported ? player.position : 0
    readonly property real length: player && player.lengthSupported ? player.length : 0
    readonly property bool canSeek: player ? player.canSeek && player.positionSupported : false

    // Holds across the short pause between tracks so the core doesn't flicker
    // back to the clock.
    property bool showing: false

    onIsPlayingChanged: {
        if (isPlaying) {
            // Deferred: `player` reads lastPlaying, so writing it here would loop
            Qt.callLater(() => { lastPlaying = player })
            graceTimer.stop()
            showing = true
        } else {
            graceTimer.restart()
        }
    }

    Component.onCompleted: showing = isPlaying

    // A player that starts takes over, even while another one keeps playing
    Instantiator {
        model: Mpris.players
        delegate: Connections {
            required property var modelData
            target: modelData
            function onIsPlayingChanged() {
                if (modelData.isPlaying) root.lastPlaying = modelData
            }
        }
    }

    Timer {
        id: graceTimer
        interval: 1500
        repeat: false
        onTriggered: root.showing = false
    }

    // MPRIS position isn't pushed; it has to be re-read while something shows it
    Timer {
        interval: 1000
        repeat: true
        running: root.isPlaying && AppState.islandPanel === "media"
        onTriggered: if (root.player) root.player.positionChanged()
    }

    function togglePlaying() { if (player) player.togglePlaying() }
    function next() { if (player) player.next() }
    function previous() { if (player) player.previous() }

    function seekToFraction(fraction) {
        if (canSeek && length > 0) player.position = fraction * length
    }

    function formatSeconds(seconds) {
        var total = Math.max(0, Math.floor(seconds))
        var secs = total % 60
        return Math.floor(total / 60) + ":" + (secs < 10 ? "0" : "") + secs
    }
}
