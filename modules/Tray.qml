import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import "root:/"
import "root:/js/AppIcons.js" as AppIcons

Rectangle {
    id: root

    readonly property var items: SystemTray.items.values
    readonly property int itemCount: items.length
    // Icon glyph/image render size — the cell itself is a full Config.barHeight
    // square (matching every other bar module), this is just the visual size
    // of the icon drawn centered inside it.
    readonly property int iconSize: Config.moduleFontSize

    visible: itemCount > 0
    // No extra padding here — matches every other grouped module's bare
    // Config.barHeight footprint with zero wrapping, so icons sit flush
    // against the shared ModuleGroup pill instead of getting their own
    // breathing room within it.
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: Config.barHeight
    color: Config.moduleBackground
    radius: Config.moduleRadius

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

                // Fixed square footprint matching every other bar module
                // (e.g. Bluetooth.qml, Audio.qml) so icon density/spacing
                // stays visually consistent across the whole bar.
                width: Config.barHeight
                height: Config.barHeight

                Rectangle {
                    anchors.fill: parent
                    radius: Config.moduleRadius
                    color: iconMa.containsMouse ? Config.moduleHoverBackground : "transparent"
                }

                Text {
                    visible: !!cell.glyph
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: cell.glyph ? cell.glyph.offsetX : 0
                    text: cell.glyph ? cell.glyph.char : ""
                    font.family: cell.glyph && cell.glyph.font ? cell.glyph.font : Config.moduleFontFamily
                    font.pixelSize: Config.moduleFontSize
                    color: Config.moduleText
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
                    colorizationColor: Theme.subtext0
                }

                MouseArea {
                    id: iconMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor

                    onEntered: AppState.showTrayTooltip(cell.label, mapToItem(null, width / 2, 0).x)
                    onExited: AppState.hideTrayTooltip()

                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            if (cell.modelData.menu) {
                                AppState.lastClickX = mapToItem(null, width / 2, 0).x
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
                                AppState.lastClickX = mapToItem(null, width / 2, 0).x
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
