pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    property alias server: notifServer
    property bool paused: false

    property var notifications: []
    property var readIds: ({})
    property var liveRefs: ({})

    readonly property int maxPopups: 5

    property alias popups: popupModel
    ListModel { id: popupModel }

    function isRead(notification) {
        return !!readIds[notification.id]
    }

    function notifAt(index) {
        if (index < 0 || index >= popupModel.count) return null
        return liveRefs[popupModel.get(index).nid] || null
    }

    function indexOfId(id) {
        for (var i = 0; i < popupModel.count; i++)
            if (popupModel.get(i).nid === id) return i
        return -1
    }

    function markRead(notification) {
        if (!notification) return
        var updated = Object.assign({}, readIds)
        updated[notification.id] = true
        readIds = updated
        var idx = indexOfId(notification.id)
        if (idx >= 0) popupModel.remove(idx)
        delete liveRefs[notification.id]
    }

    function dismissNotification(notification) {
        if (!notification) return
        var idx = indexOfId(notification.id)
        if (idx >= 0) popupModel.remove(idx)
        delete liveRefs[notification.id]
        notification.tracked = false
        notifications = notifServer.trackedNotifications.values.slice().reverse()
    }

    function removePopup(notification) {
        if (!notification) return
        var idx = indexOfId(notification.id)
        if (idx >= 0) popupModel.remove(idx)
        delete liveRefs[notification.id]
    }

    function clearAll() {
        for (var i = notifServer.trackedNotifications.values.length - 1; i >= 0; i--)
            notifServer.trackedNotifications.values[i].tracked = false
        notifications = []
        popupModel.clear()
        liveRefs = {}
        readIds = {}
    }

    function togglePause() { paused = !paused }

    NotificationServer {
        id: notifServer
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        keepOnReload: true

        onNotification: notif => {
            if (!notif.transient) notif.tracked = true

            if (!paused && !notif.lastGeneration) {
                // Remove duplicate id if present
                var dup = indexOfId(notif.id)
                if (dup >= 0) {
                    delete liveRefs[notif.id]
                    popupModel.remove(dup)
                }
                // Trim oldest if at cap
                if (popupModel.count >= maxPopups) {
                    var oldId = popupModel.get(popupModel.count - 1).nid
                    delete liveRefs[oldId]
                    popupModel.remove(popupModel.count - 1)
                }
                liveRefs[notif.id] = notif
                popupModel.insert(0, { nid: notif.id })
            }

            notifications = notifServer.trackedNotifications.values.slice().reverse()
        }
    }

    Connections {
        target: notifServer.trackedNotifications
        function onValuesChanged() {
            notifications = notifServer.trackedNotifications.values.slice().reverse()
        }
    }
}
