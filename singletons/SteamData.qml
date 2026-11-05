pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The installed Steam games from scripts/steam-games.sh, shaped like the desktop entries the
// launcher lists. Starting one through Steam also starts Steam if it's closed.
Singleton {
    id: root

    property var games: []  // [{ id, name, genericName, execString }]

    function refresh() {
        if (!listProcess.running) listProcess.running = true
    }

    Process {
        id: listProcess
        command: [Quickshell.shellDir + "/scripts/steam-games.sh"]
        stdout: SplitParser {
            property var incoming: []
            onRead: line => {
                var parts = line.split("\t")
                incoming = incoming.concat([{
                    id: "steam-" + parts[0],
                    name: parts[1],
                    genericName: "Steam game",
                    execString: "steam steam://rungameid/" + parts[0]
                }])
            }
        }
        onExited: {
            root.games = listProcess.stdout.incoming
            listProcess.stdout.incoming = []
        }
    }
}
