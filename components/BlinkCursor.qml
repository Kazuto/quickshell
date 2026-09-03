import QtQuick

// Reusable blinking-cursor driver for search-style text inputs.
// Bind a Rectangle's `visible` to `cursorVisible`, and set `active` to the
// enclosing overlay's visibility so the blink resets whenever it opens.
QtObject {
    id: root

    property bool active: false
    property bool cursorVisible: true

    property Timer _timer: Timer {
        interval: 530
        repeat: true
        running: root.active
        onTriggered: root.cursorVisible = !root.cursorVisible
        onRunningChanged: if (running) root.cursorVisible = true
    }
}
