import QtQuick
import "root:/"

Canvas {
    id: root

    property real progress: 1  // 0–1, remaining share
    property color ringColor: Theme.accentSky
    property int ringWidth: 3

    implicitWidth: 18
    implicitHeight: 18

    onProgressChanged: requestPaint()
    onRingColorChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        var radius = (width - ringWidth) / 2
        var start = -Math.PI / 2
        ctx.reset()
        ctx.lineWidth = ringWidth
        ctx.lineCap = "round"
        ctx.strokeStyle = Theme.surfaceHigh
        ctx.beginPath()
        ctx.arc(width / 2, height / 2, radius, 0, 2 * Math.PI)
        ctx.stroke()
        ctx.strokeStyle = ringColor
        ctx.beginPath()
        ctx.arc(width / 2, height / 2, radius, start, start + 2 * Math.PI * progress)
        ctx.stroke()
    }
}
