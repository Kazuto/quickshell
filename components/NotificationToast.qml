import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "root:/"
import "root:/singletons"

Rectangle {
    id: root

    required property var notification
    property bool slideIn: true

    signal dismissed()

    readonly property bool hovered: hoverArea.containsMouse

    width: 320
    height: toastContent.implicitHeight + 20 + (progressBar.visible ? 10 : 0)
    color: Theme.mantle
    radius: Config.overlayRadius
    border.color: urgencyColor()
    border.width: 2
    opacity: 1
    clip: true

    x: 340

    function urgencyColor() {
        if (!notification) return Theme.blue
        switch (notification.urgency) {
            case NotificationUrgency.Critical: return Theme.red
            case NotificationUrgency.Low:      return Theme.surface1
            default:                           return Theme.blue
        }
    }

    function formatTime(notif) {
        if (!notif) return ""
        var d = new Date()
        var h = d.getHours()
        var m = d.getMinutes()
        var ampm = h >= 12 ? "PM" : "AM"
        h = h % 12 || 12
        return h + ":" + (m < 10 ? "0" + m : m) + " " + ampm
    }

    // expireTimeout from Quickshell is the raw DBus millisecond value:
    //  -1 = server should decide (use our default 5s)
    //   0 = never expire (persistent, e.g. critical alerts)
    //  >0 = explicit timeout in ms, capped at 30s
    function computeInterval(notif) {
        if (!notif) return 5000
        var t = notif.expireTimeout
        if (t < 0)  return 5000   // -1 = server default
        if (t === 0) return 0     // 0 = never auto-close
        return Math.min(t, 30000)
    }

    NumberAnimation on x {
        from: slideIn ? 340 : 0
        to: 0
        duration: slideIn ? 250 : 0
        easing.type: Easing.OutCubic
        running: true
    }

    SequentialAnimation {
        id: dismissAnim
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: 200; easing.type: Easing.InCubic }
        ScriptAction { script: root.dismissed() }
    }

    function startDismiss() {
        autoClose.stop()
        dismissAnim.start()
    }

    Timer {
        id: autoClose
        interval: 5000
        running: false
        repeat: false
        onTriggered: startDismiss()
    }

    Column {
        id: toastContent
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 12
            leftMargin: 14
            rightMargin: 14
        }
        spacing: 4

        // Top row: app name (left), time (right)
        Item {
            width: parent.width
            height: 16

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: notification ? notification.appName : ""
                color: root.urgencyColor()
                font.pixelSize: 10
                font.family: Config.moduleFontFamily
                elide: Text.ElideRight
                width: parent.width - timeText.width - 6
            }

            Text {
                id: timeText
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.formatTime(notification)
                color: Theme.overlay0
                font.pixelSize: 10
                font.family: Config.moduleFontFamily
            }
        }

        // Summary
        Text {
            width: parent.width
            text: notification ? notification.summary : ""
            color: Theme.text
            font.pixelSize: 13
            font.bold: true
            font.family: Config.moduleFontFamily
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            visible: text !== ""
        }

        // Body
        Text {
            width: parent.width
            text: notification ? notification.body.replace(/<[^>]*>/g, '') : ""
            color: Theme.subtext0
            font.pixelSize: 12
            font.family: Config.moduleFontFamily
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            visible: text !== ""
        }

        Item { width: 1; height: 4 }
    }

    // Progress bar
    Rectangle {
        id: progressBar
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            bottomMargin: 6
            leftMargin: 6
            rightMargin: 6
        }
        height: 3
        radius: 2
        color: Theme.surface0
        visible: !notification || !notification.lastGeneration

        Rectangle {
            id: progressFill
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: parent.width
            radius: 2
            color: root.urgencyColor()
        }
    }

    Component.onCompleted: {
        if (!notification || notification.lastGeneration) return
        var ms = computeInterval(notification)
        if (ms <= 0) return
        autoClose.interval = ms
        autoClose.start()
        progressAnim.from = progressBar.width
        progressAnim.duration = ms
        progressAnim.start()
    }

    NumberAnimation {
        id: progressAnim
        target: progressFill
        property: "width"
        from: 0
        to: 0
        duration: 5000
        easing.type: Easing.Linear
        running: false
    }

    // Left-click = mark read, right-click = dismiss from history
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        z: -1
        onEntered: { autoClose.stop(); progressAnim.pause() }
        onExited:  { autoClose.start(); progressAnim.resume() }
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                autoClose.stop()
                if (notification) NotificationData.dismissNotification(notification)
                root.dismissed()
            } else {
                startDismiss()
            }
        }
    }
}
