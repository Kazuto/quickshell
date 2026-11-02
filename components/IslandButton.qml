import QtQuick
import "root:/"

Rectangle {
    id: root

    property string label: ""
    property string iconName: ""
    property int iconSize: 16
    property bool leadingDot: false
    property string variant: "raised"  // raised | selected | accent | sky | rec | warn
    property bool active: true
    signal clicked()

    readonly property color contentColor: !active ? Theme.textFaint
        : variant === "accent" || variant === "sky" || variant === "rec" || variant === "warn" ? Theme.textOnAccent
        : Theme.text

    implicitWidth: label !== "" ? content.implicitWidth + 32 : implicitHeight
    implicitHeight: 44
    radius: height / 2
    opacity: active ? 1 : 0.6

    color: {
        if (variant === "accent") return Theme.accent
        if (variant === "sky") return Theme.accentSky
        if (variant === "rec") return Theme.rec
        if (variant === "warn") return Theme.warn
        if (variant === "selected") return Theme.surfaceHigh
        return mouse.containsMouse && active ? Theme.surfaceHigh : Theme.surfaceLow
    }

    Behavior on color {
        ColorAnimation { duration: Config.animationDuration }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 8

        Rectangle {
            visible: root.leadingDot
            width: 8
            height: 8
            radius: 4
            color: root.contentColor
            anchors.verticalCenter: parent.verticalCenter
        }

        SvgIcon {
            visible: root.iconName !== ""
            name: root.iconName
            size: root.iconSize
            color: root.contentColor
            anchors.verticalCenter: parent.verticalCenter
        }

        IslandLabel {
            visible: root.label !== ""
            text: root.label
            kind: "island"
            color: root.contentColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.active
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
