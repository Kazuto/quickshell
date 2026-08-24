import QtQuick
import Quickshell
import Quickshell.Hyprland
import "root:/"

Rectangle {
    property int startWorkspace: 1  // Starting workspace number
    property string defaultIcon: ""  // If set, use this icon for all workspaces

    implicitWidth: workspaceRow.implicitWidth + Config.moduleHorizontalPadding
    implicitHeight: Config.barHeight
    color: Config.moduleBackground
    radius: Config.moduleRadius

    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: Config.workspaceSpacing

        Repeater {
            model: defaultIcon !== "" ? [
                {num: startWorkspace + 0, icon: defaultIcon},
                {num: startWorkspace + 1, icon: defaultIcon},
            ] : [
                {num: startWorkspace + 0, icon: Icon.chrome},
                {num: startWorkspace + 1, icon: Icon.ghostty},
                {num: startWorkspace + 2, icon: Icon.database},
                {num: startWorkspace + 3, icon: Icon.code},
                {num: startWorkspace + 4, icon: Icon.thunderbird},
            ]

            delegate: Item {
                property int workspaceNum: modelData.num
                property string workspaceIcon: modelData.icon
                property bool isActive: false
                property bool hasWindows: false

                Binding on isActive {
                    value: {
                        if (!Hyprland.focusedWorkspace) return false
                        return Hyprland.focusedWorkspace.id === workspaceNum
                    }
                    when: Hyprland.focusedWorkspace !== undefined
                }

                Binding on hasWindows {
                    value: {
                        for (var i in Hyprland.workspaces.values) {
                            var ws = Hyprland.workspaces.values[i]
                            if (ws.id === workspaceNum) {
                                return ws.windows && ws.windows.length > 0
                            }
                        }
                        return false
                    }
                    when: Hyprland.workspaces !== undefined
                }

                width: Config.workspaceSize
                height: Config.workspaceSize

                Text {
                    anchors.centerIn: parent
                    text: workspaceIcon
                    color: isActive ? Config.workspaceActive :
                           (wsMouseArea.containsMouse ? Config.workspaceActive :
                           (hasWindows ? Config.moduleText : Config.moduleTextMuted))
                    font.pixelSize: Config.workspaceIconSize
                    font.family: Config.moduleFontFamily
                    z: 0

                    Behavior on color {
                        ColorAnimation { duration: Config.animationDuration }
                    }
                }

                MouseArea {
                    id: wsMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    z: 1
                    onClicked: {
                        Hyprland.dispatch("workspace " + workspaceNum)
                    }
                }
            }
        }
    }
}
