import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/singletons"

PanelWindow {
    id: root

    // Only anchor to bottom — no left/right so the window is only as wide as the card
    anchors.bottom: true
    implicitWidth: card.width
    implicitHeight: card.height + card.bottomMargin

    color: "transparent"
    visible: OsdData.visible

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // ── OSD card ───────────────────────────────────────────────────────────
    Rectangle {
        id: card
        width: 260
        height: 64
        readonly property int bottomMargin: 48

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: bottomMargin

        color: Config.alpha(Theme.base, 0.92)
        radius: 16
        border.color: Theme.surface1
        border.width: 1

        opacity: OsdData.visible ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Row {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 20
                rightMargin: 20
            }
            spacing: 14

            // ── Icon — fixed width so the bar never shifts ─────────────────
            Text {
                width: 20
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
                font.family: Config.moduleFontFamily
                font.pixelSize: 16
                color: OsdData.muted ? Theme.overlay1 : Theme.blue
                text: {
                    if (OsdData.type === "brightness") return "\uf185"   // sun
                    if (OsdData.type === "mute")       return "\uf6a9"   // volume-mute
                    var v = OsdData.value
                    if (v === 0)  return "\uf026"                        // volume-off
                    if (v < 50)   return "\uf027"                        // volume-down
                    return "\uf028"                                      // volume-up
                }
            }

            // ── Bar + labels ───────────────────────────────────────────────
            Column {
                width: parent.width - 20 - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Item {
                    width: parent.width
                    height: labelLeft.implicitHeight

                    Text {
                        id: labelLeft
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: OsdData.type === "brightness" ? "Brightness" : "Volume"
                        color: Theme.subtext0
                        font.pixelSize: 11
                        font.family: Config.moduleFontFamily
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: OsdData.type === "mute" ? "Muted" : (OsdData.value + "%")
                        color: OsdData.type === "mute" ? Theme.overlay1 : Theme.text
                        font.pixelSize: 11
                        font.family: Config.moduleFontFamily
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.surface1

                    Rectangle {
                        width: parent.width * (OsdData.type === "mute" ? 0 : OsdData.value / 100)
                        height: parent.height
                        radius: parent.radius
                        color: OsdData.type === "brightness" ? Theme.yellow : Theme.blue
                        opacity: OsdData.type === "mute" ? 0.3 : 1

                        Behavior on width {
                            NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }
}
