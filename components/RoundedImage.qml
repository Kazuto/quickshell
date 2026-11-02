import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property alias source: image.source
    property alias status: image.status
    property int radius: 12

    Image {
        id: image
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        visible: false
    }

    Rectangle {
        id: shape
        anchors.fill: parent
        radius: root.radius
        visible: false
    }

    OpacityMask {
        anchors.fill: parent
        source: image
        maskSource: shape
        visible: image.status === Image.Ready
    }
}
