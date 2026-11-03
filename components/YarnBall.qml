import QtQuick
import "root:/"

// A small ball of yarn, for tying off the end of a YarnStrand. Only drawn once per color.
Canvas {
    id: ball

    property color yarn: Theme.accent

    implicitWidth: 18
    implicitHeight: 18

    onYarnChanged: requestPaint()

    onPaint: {
        var context = getContext("2d")
        var radius = width / 2

        context.reset()
        context.translate(radius, radius)

        context.beginPath()
        context.arc(0, 0, radius - 1, 0, Math.PI * 2)
        context.fillStyle = yarn
        context.fill()
        context.clip()

        // Three bundles of strands wound over each other at different angles
        context.lineWidth = radius * 0.13
        for (var bundle = 0; bundle < 3; bundle++) {
            context.save()
            context.rotate(bundle * Math.PI * 2 / 3 + 0.5)
            context.strokeStyle = bundle === 1 ? Qt.lighter(yarn, 1.14) : Qt.darker(yarn, 1.32)
            for (var strand = 0; strand < 3; strand++) {
                context.beginPath()
                context.arc(-radius * 0.95, 0, radius * (0.55 + strand * 0.34), -1.1, 1.1)
                context.stroke()
            }
            context.restore()
        }

        // Round it off
        var shade = context.createRadialGradient(-radius * 0.3, -radius * 0.35, radius * 0.1, 0, 0, radius)
        shade.addColorStop(0, "#30ffffff")
        shade.addColorStop(0.55, "#00000000")
        shade.addColorStop(1, "#66000000")
        context.fillStyle = shade
        context.fillRect(-radius, -radius, width, height)
    }
}
