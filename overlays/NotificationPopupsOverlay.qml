import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/singletons"
import "root:/components"

PanelWindow {
    anchors { top: true; right: true; bottom: true; left: true }

    color: "transparent"
    visible: NotificationData.popups.count > 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    mask: Region { item: stackRoot }

    Item {
        id: stackRoot

        readonly property int maxVisible: 3
        readonly property int peekOffset: 10
        readonly property int visibleDepths: Math.max(0, Math.min(NotificationData.popups.count - 1, maxVisible - 1))

        anchors {
            top: parent.top
            right: parent.right
            topMargin: Config.barHeight + Config.barMarginTop + 8
            rightMargin: 10
        }

        width:  NotificationData.popups.count > 0 ? 320 + visibleDepths * peekOffset : 0
        height: NotificationData.popups.count > 0 ? 200 + visibleDepths * peekOffset : 0

        visible: NotificationData.popups.count > 0

        Repeater {
            model: Math.min(NotificationData.popups.count, stackRoot.maxVisible)

            delegate: NotificationToast {
                id: toastDelegate
                required property int index

                readonly property int depth: index  // 0 = front

                notification: NotificationData.notifAt(index)

                anchors.top:         stackRoot.top
                anchors.right:       stackRoot.right
                anchors.topMargin:   depth * stackRoot.peekOffset
                anchors.rightMargin: depth * stackRoot.peekOffset

                scale:           1.0 - depth * 0.04
                transformOrigin: Item.TopRight
                opacity:         1.0 - depth * 0.25

                enabled: depth === 0
                z:       stackRoot.maxVisible - depth

                // Only the front card slides in; back cards just appear
                slideIn: depth === 0

                onDismissed: NotificationData.removePopup(notification)
            }
        }
    }
}
