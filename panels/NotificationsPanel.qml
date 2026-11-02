import QtQuick
import Quickshell
import "root:/"
import "root:/singletons"
import "root:/components"

// B and B2: the bell glyph. Desktop notifications and polled sources land in one
// list, newest first, and the chips filter by source. GitHub threads mirror what
// GitHub reports as unread, so they leave by being read there, not from here.
PanelFrame {
    id: panel

    property string filter: "all"
    property var entries: []

    readonly property int appCount: NotificationData.notifications.length
    readonly property int githubCount: GitHubData.notifications.length
    readonly property var filters: [
        { id: "all", label: "All", count: appCount + githubCount },
        { id: "github", label: "GitHub", count: githubCount },
        { id: "apps", label: "Apps", count: appCount }
    ]
    readonly property var shownEntries: {
        var source = filter
        return source === "all" ? entries : entries.filter(entry => entry.source === source)
    }

    spacing: 12

    function rebuild() {
        var result = []

        // App notifications stay collapsed per app, as in the design
        var apps = NotificationData.groups()
        for (var i = 0; i < apps.length; i++) {
            var items = apps[i].items
            var latest = items[0]
            result.push({
                source: "apps",
                items: items,
                label: apps[i].app + (items.length > 1 ? " · " + items.length : ""),
                summary: NotificationData.plainText(latest.summary),
                detail: items.length > 1
                    ? "+" + (items.length - 1) + " more · " + NotificationData.plainText(items[1].summary)
                    : NotificationData.plainText(latest.body),
                detailLit: false,
                at: NotificationData.receivedAt[latest.id] || 0,
                iconName: "chat",
                image: latest.image || (latest.appIcon ? Quickshell.iconPath(latest.appIcon, true) : "")
            })
        }

        var threads = GitHubData.notifications
        for (var j = 0; j < threads.length; j++) {
            result.push({
                source: "github",
                thread: threads[j],
                label: threads[j].repo + " · " + GitHubData.typeLabel(threads[j].type),
                summary: threads[j].title,
                detail: threads[j].unread ? "unread" : "",
                detailLit: true,
                at: new Date(threads[j].updated_at).getTime(),
                iconName: GitHubData.typeIcon(threads[j].type),
                image: ""
            })
        }

        result.sort(function(a, b) { return b.at - a.at })
        entries = result
    }

    function open(entry) {
        if (entry.source === "github") {
            if (entry.thread.url) Qt.openUrlExternally(entry.thread.url)
            AppState.closePanel()
        } else {
            NotificationData.invokeDefault(entry.items[0])
            dismiss(entry)
        }
    }

    function dismiss(entry) {
        for (var i = 0; i < entry.items.length; i++) NotificationData.dismissNotification(entry.items[i])
    }

    function nextFilter() {
        for (var i = 0; i < filters.length; i++) {
            if (filters[i].id === filter) {
                filter = filters[(i + 1) % filters.length].id
                return
            }
        }
    }

    function handleKey(event) {
        if (event.key !== Qt.Key_Tab) return
        nextFilter()
        event.accepted = true
    }

    Component.onCompleted: {
        GitHubData.refresh()
        rebuild()
    }

    Connections {
        target: NotificationData
        function onNotificationsChanged() { panel.rebuild() }
    }

    Connections {
        target: GitHubData
        function onNotificationsChanged() { panel.rebuild() }
    }

    // Ages are relative, so the labels need refreshing while the panel is open
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: panel.rebuild()
    }

    headerLeft: [
        SvgIcon {
            name: "bell"
            size: 16
            color: Theme.text
            anchors.verticalCenter: parent.verticalCenter
        },
        IslandLabel {
            text: "Notifications"
            kind: "island"
            anchors.verticalCenter: parent.verticalCenter
        }
    ]

    headerRight: [
        IslandLabel {
            visible: panel.filter !== "github"
            text: "Do not disturb"
            kind: "meta"
            anchors.verticalCenter: parent.verticalCenter
        },
        CheckBox {
            visible: panel.filter !== "github"
            checked: NotificationData.paused
            anchors.verticalCenter: parent.verticalCenter
            onToggled: NotificationData.togglePause()
        },
        IslandButton {
            visible: panel.filter === "github"
            implicitHeight: 28
            iconName: "refresh"
            iconSize: 12
            anchors.verticalCenter: parent.verticalCenter
            onClicked: GitHubData.refresh()
        }
    ]

    Row {
        spacing: 6

        Repeater {
            model: panel.filters

            delegate: FilterChip {
                required property var modelData

                label: modelData.label + " " + modelData.count
                selected: panel.filter === modelData.id
                onClicked: panel.filter = modelData.id
            }
        }
    }

    Flickable {
        width: parent.width
        height: Math.min(cards.implicitHeight, 420)
        contentHeight: cards.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        visible: panel.shownEntries.length > 0

        Column {
            id: cards
            width: parent.width
            spacing: 12

            Repeater {
                model: panel.shownEntries

                delegate: Rectangle {
                    id: card

                    required property var modelData

                    readonly property bool canDismiss: modelData.source !== "github"

                    width: cards.width
                    height: cardColumn.implicitHeight + 28
                    radius: Config.cardRadius
                    color: cardMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceLow

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: panel.open(card.modelData)
                    }

                    IconDisc {
                        id: icon
                        x: 14
                        y: 14
                        diameter: 32
                        iconName: card.modelData.iconName
                        imageSource: card.modelData.image
                    }

                    Column {
                        id: cardColumn
                        anchors.left: icon.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        y: 14
                        spacing: 4

                        Item {
                            width: parent.width
                            height: 14

                            IslandLabel {
                                width: parent.width - 40
                                anchors.verticalCenter: parent.verticalCenter
                                text: card.modelData.label
                                kind: "meta"
                            }

                            IslandLabel {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !closeIcon.visible
                                text: NotificationData.ageSince(card.modelData.at)
                                kind: "meta"
                            }

                            SvgIcon {
                                id: closeIcon
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                visible: card.canDismiss && (cardMouse.containsMouse || closeMouse.containsMouse)
                                name: "close"
                                size: 12
                                color: closeMouse.containsMouse ? Theme.text : Theme.textDim

                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: panel.dismiss(card.modelData)
                                }
                            }
                        }

                        IslandLabel {
                            width: parent.width
                            text: card.modelData.summary
                            kind: "island"
                        }

                        IslandLabel {
                            width: parent.width
                            visible: text !== ""
                            text: card.modelData.detail
                            kind: "meta"
                            color: card.modelData.detailLit ? Theme.accent : Theme.textDim
                        }
                    }
                }
            }
        }
    }

    IslandLabel {
        visible: panel.shownEntries.length === 0
        width: parent.width
        height: 72
        horizontalAlignment: Text.AlignHCenter
        text: panel.filter === "github" ? "No unread threads" : "No notifications"
        kind: "meta"
    }

    Item {
        visible: panel.filter !== "github" && panel.appCount > 0
        width: parent.width
        height: 32

        IslandButton {
            anchors.right: parent.right
            implicitHeight: 32
            label: "Clear all"
            onClicked: NotificationData.clearAll()
        }
    }
}
