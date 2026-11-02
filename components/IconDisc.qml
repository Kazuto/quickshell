import QtQuick
import "root:/"

// Round icon holder used at the start of pills and notification cards
Rectangle {
    id: root

    property string iconName: ""
    property string imageSource: ""
    property int iconSize: 14
    property int diameter: 24

    implicitWidth: diameter
    implicitHeight: diameter
    radius: diameter / 2
    color: Theme.surfaceHigh

    SvgIcon {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        name: root.iconName
        size: root.iconSize
        color: Theme.textDim
    }

    RoundedImage {
        id: image
        anchors.fill: parent
        source: root.imageSource
        radius: root.radius
    }
}
