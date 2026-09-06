import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"

PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Stack of {opener, title} entries for drilling into submenus. The root
    // opener always mirrors AppState.trayMenuTarget; entering a submenu
    // pushes a new opener bound to that entry, leaving so it can pop back.
    property var submenuStack: []
    readonly property var currentChildren: submenuStack.length > 0
        ? submenuStack[submenuStack.length - 1].opener.children
        : rootOpener.children
    readonly property string currentTitle: submenuStack.length > 0
        ? submenuStack[submenuStack.length - 1].title
        : ""

    QsMenuOpener {
        id: rootOpener
        menu: AppState.trayMenuTarget
    }

    Component {
        id: submenuOpenerComponent
        QsMenuOpener {}
    }

    function enterSubmenu(entry) {
        var opener = submenuOpenerComponent.createObject(root, { menu: entry })
        if (!opener) return
        var stack = submenuStack.slice()
        stack.push({ opener: opener, title: entry.text || "" })
        submenuStack = stack
    }

    function leaveSubmenu() {
        if (submenuStack.length === 0) return
        var stack = submenuStack.slice()
        var top = stack.pop()
        submenuStack = stack
        top.opener.destroy()
    }

    function resetMenu() {
        var stack = submenuStack
        submenuStack = []
        for (var i = stack.length - 1; i >= 0; i--) stack[i].opener.destroy()
    }

    function close() {
        resetMenu()
        AppState.closeTrayMenu()
    }

    onVisibleChanged: {
        if (!visible) resetMenu()
    }

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
        z: -1
    }

    Rectangle {
        id: menuCard
        anchors {
            top: parent.top
            topMargin: 12
        }
        // Use Screen.* rather than root.width/height for these clamps —
        // root's own geometry briefly reads 0 on the very first frame
        // before the compositor assigns the surface its real size, which
        // would otherwise produce a momentary negative height/bad position.
        x: Math.min(Math.max(AppState.lastClickX - width / 2, 10), Screen.width - width - 10)

        width: 220
        height: Math.min(contentColumn.implicitHeight + 16, Screen.height - 100)
        color: Theme.mantle
        radius: Config.overlayRadius
        border.color: Theme.surface0
        border.width: 1

        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
            id: contentColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 2

            // Back row, shown only while inside a submenu
            Row {
                width: parent.width
                height: 28
                visible: root.submenuStack.length > 0
                spacing: 8

                Rectangle {
                    width: parent.width
                    height: 28
                    color: backMa.containsMouse ? Config.moduleHoverBackground : "transparent"
                    radius: Config.moduleRadius

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        spacing: 6

                        Text {
                            text: "\uf104"
                            color: Theme.subtext0
                            font.pixelSize: 11
                            font.family: Config.moduleFontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: root.currentTitle
                            color: Theme.text
                            font.pixelSize: 12
                            font.family: Config.moduleFontFamily
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: backMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.leaveSubmenu()
                    }
                }
            }

            Repeater {
                model: root.currentChildren

                delegate: Item {
                    id: menuRow
                    required property var modelData
                    required property int index

                    width: contentColumn.width
                    height: modelData.isSeparator ? 9 : 30

                    Rectangle {
                        visible: menuRow.modelData.isSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: Theme.surface0
                    }

                    Rectangle {
                        visible: !menuRow.modelData.isSeparator
                        anchors.fill: parent
                        radius: Config.moduleRadius
                        color: rowMa.containsMouse && menuRow.modelData.enabled
                            ? Config.moduleHoverBackground : "transparent"
                        opacity: menuRow.modelData.enabled ? 1.0 : 0.4

                        Text {
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                leftMargin: 10
                                right: chevron.left
                                rightMargin: 6
                            }
                            text: menuRow.modelData.text || ""
                            color: Theme.text
                            font.pixelSize: 12
                            font.family: Config.moduleFontFamily
                            elide: Text.ElideRight
                        }

                        Text {
                            id: chevron
                            visible: menuRow.modelData.hasChildren
                            anchors {
                                verticalCenter: parent.verticalCenter
                                right: parent.right
                                rightMargin: 8
                            }
                            text: "\uf105"
                            color: Theme.subtext0
                            font.pixelSize: 10
                            font.family: Config.moduleFontFamily
                        }

                        MouseArea {
                            id: rowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: menuRow.modelData.enabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (menuRow.modelData.hasChildren) {
                                    root.enterSubmenu(menuRow.modelData)
                                } else {
                                    menuRow.modelData.triggered()
                                    root.close()
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: root.currentChildren && root.currentChildren.values && root.currentChildren.values.length === 0
                text: "No actions"
                color: Theme.overlay1
                font.pixelSize: 11
                font.family: Config.moduleFontFamily
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
