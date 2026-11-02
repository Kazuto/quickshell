import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import "root:/"
import "root:/js/AppIcons.js" as AppIcons

Rectangle {
    id: root

    required property var screen
    readonly property var items: SystemTray.items.values
    // Hovered icon's name, shown by the row hosting the tray
    property string hoveredLabel: ""
    readonly property int itemCount: items.length
    readonly property int cellSize: 28
    readonly property int iconSize: 14

    visible: itemCount > 0
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: cellSize
    color: "transparent"

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: root.items

            delegate: Item {
                id: cell
                required property var modelData

                readonly property bool isSymbolic: {
                    var name = String(cell.modelData.icon || "").split("?")[0]
                    return name.slice(-9) === "-symbolic"
                }

                // Prefer a known monochrome glyph (matches the style used by
                // WindowTitle's active-window icon) over the app's own
                // colored tray icon, so the tray blends into the bar instead
                // of looking like a row of mismatched logos.
                readonly property var glyph: AppIcons.glyphFor(cell.modelData.id)
                readonly property string label: AppIcons.labelFor(cell.modelData.id)
                    || cell.modelData.tooltipTitle || cell.modelData.title || cell.modelData.id || ""

                width: root.cellSize
                height: root.cellSize

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: iconMa.containsMouse ? Theme.surfaceHigh : "transparent"
                }

                Text {
                    visible: !!cell.glyph
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: cell.glyph ? cell.glyph.offsetX : 0
                    text: cell.glyph ? cell.glyph.char : ""
                    font.family: cell.glyph && cell.glyph.font ? cell.glyph.font : Config.moduleFontFamily
                    font.pixelSize: root.iconSize
                    color: Theme.text
                }

                Image {
                    id: trayIconImage
                    anchors.centerIn: parent
                    width: root.iconSize
                    height: root.iconSize
                    source: cell.glyph ? "" : String(cell.modelData.icon || "")
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: !cell.glyph && !cell.isSymbolic
                    sourceSize.width: width * Screen.devicePixelRatio
                    sourceSize.height: height * Screen.devicePixelRatio
                    layer.enabled: !cell.glyph && cell.isSymbolic
                }

                // Symbolic icons ship a fixed (often near-white) fill meant to
                // be recolored by the host; tint them to match the bar text
                // color so they don't disappear or clash against the theme.
                // Only applies to the raster fallback path (no known glyph).
                MultiEffect {
                    anchors.fill: trayIconImage
                    source: trayIconImage
                    visible: !cell.glyph && cell.isSymbolic
                    colorization: 1.0
                    colorizationColor: Theme.textDim
                }

                MouseArea {
                    id: iconMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor

                    onEntered: root.hoveredLabel = cell.label
                    onExited: root.hoveredLabel = ""

                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            if (cell.modelData.menu) {
                                AppState.centerOverlaysOn(root.screen)
                                AppState.openTrayMenu(cell.modelData.menu)
                            } else if (cell.modelData.onlyMenu !== true) {
                                cell.modelData.display(iconMa.QsWindow.window,
                                    mapToItem(iconMa.QsWindow.contentItem, mouse.x, mouse.y).x,
                                    mapToItem(iconMa.QsWindow.contentItem, mouse.x, mouse.y).y)
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            cell.modelData.secondaryActivate()
                        } else if (cell.modelData.onlyMenu) {
                            if (cell.modelData.menu) {
                                AppState.centerOverlaysOn(root.screen)
                                AppState.openTrayMenu(cell.modelData.menu)
                            }
                        } else {
                            cell.modelData.activate()
                        }
                    }

                    onWheel: function(wheel) {
                        cell.modelData.scroll(wheel.angleDelta.y, false)
                    }
                }
            }
        }
    }
}
