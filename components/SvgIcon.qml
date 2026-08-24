import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    property string name: ""
    property int size: 16
    property color color: "white"

    width: size
    height: size

    Image {
        id: iconImage
        anchors.fill: parent
        source: name ? "root:/assets/icons/" + name + ".svg" : ""
        sourceSize.width: size
        sourceSize.height: size
        smooth: true
        visible: false
    }

    ColorOverlay {
        anchors.fill: iconImage
        source: iconImage
        color: parent.color
    }
}
