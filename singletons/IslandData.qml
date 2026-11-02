pragma Singleton

import QtQuick
import Quickshell
import "root:/"
import "root:/singletons"

// Who gets the island. Priority from the design: recording (left bubble),
// notification, OSD, media, timer (right bubble), idle. A transient never
// evicts an activity; it borrows the core and hands it back.
Singleton {
    id: root

    // Snapshot of the notification borrowing the core, or null. A copy rather
    // than the live object, which the sending app can destroy at any moment.
    property var notification: null

    readonly property bool osdActive: OsdData.visible
    readonly property bool transientActive: notification !== null || osdActive

    readonly property string core: notification !== null ? "notification"
        : osdActive ? "osd"
        : MediaData.showing ? "media"
        : "idle"

    readonly property bool leftBubble: RecorderData.recording
    readonly property bool rightBubble: TimerData.running

    readonly property date now: clock.date
    readonly property string clockText: Qt.formatDateTime(clock.date, "HH:mm")
    readonly property string dateText: Qt.formatDateTime(clock.date, "ddd d")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Popups are newest-first, so the head of the queue is the last row
    function showNext() {
        var model = NotificationData.popups
        while (model.count > 0) {
            var live = NotificationData.notifAt(model.count - 1)
            if (live) {
                notification = {
                    id: live.id,
                    app: live.appName || "notification",
                    summary: NotificationData.plainText(live.summary) || NotificationData.plainText(live.body),
                    icon: live.image || (live.appIcon ? Quickshell.iconPath(live.appIcon, true) : "")
                }
                if (AppState.islandPanel === "") holdTimer.restart()
                return
            }
            model.remove(model.count - 1)
        }
        notification = null
    }

    function finishCurrent() {
        var index = notification ? NotificationData.indexOfId(notification.id) : -1
        if (index >= 0) NotificationData.removePopup(NotificationData.notifAt(index))
        notification = null
        showNext()
    }

    Connections {
        target: NotificationData.popups
        function onCountChanged() {
            if (root.notification === null) root.showNext()
        }
    }

    // A panel covers the core, so the hold only runs once it can actually be seen
    Connections {
        target: AppState
        function onIslandPanelChanged() {
            if (AppState.islandPanel !== "") holdTimer.stop()
            else if (root.notification !== null) holdTimer.restart()
        }
    }

    Timer {
        id: holdTimer
        interval: Config.notificationHoldMs
        repeat: false
        onTriggered: root.finishCurrent()
    }
}
