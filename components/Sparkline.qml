import QtQuick
import "root:/"

// Recent history as a thin line
Canvas {
    id: root

    property var values: []
    property real maxValue: 100
    property color lineColor: Theme.accentSky

    implicitHeight: 28

    onValuesChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        if (!values || values.length < 2) return
        var step = width / (values.length - 1)
        ctx.beginPath()
        for (var i = 0; i < values.length; i++) {
            var y = height - 1 - (height - 2) * Math.min(1, values[i] / maxValue)
            if (i === 0) ctx.moveTo(0, y)
            else ctx.lineTo(i * step, y)
        }
        ctx.lineWidth = 1.5
        ctx.strokeStyle = lineColor
        ctx.stroke()
    }
}
