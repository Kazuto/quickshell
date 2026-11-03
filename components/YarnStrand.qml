import QtQuick
import Quickshell
import "root:/"

// A length of yarn from a fixed end to a moving one. The two middle points of the curve
// carry its weight: they hang below the straight line by however much slack there is,
// and swing after it when the end moves. shaders/yarn.* do the drawing.
ShaderEffect {
    id: strand

    required property point fixedEnd
    required property point movingEnd

    // Full length of the yarn: pulled this far it goes taut
    property real reach: 1000
    // Half the strip's width, which includes room for fuzz around the wool
    property real thickness: 8
    property real phase: 0

    readonly property real maxSag: 240
    readonly property real minSag: 22
    readonly property real stiffness: 42
    readonly property real damping: 6.5
    readonly property real swayPixels: 3

    // Uniforms for the shaders
    property point p0: fixedEnd
    property point p1: fixedEnd
    property point p2: fixedEnd
    property point p3: Qt.point(
        fixedEnd.x + (movingEnd.x - fixedEnd.x) * unspool,
        fixedEnd.y + (movingEnd.y - fixedEnd.y) * unspool
    )
    property real strandLength: 0
    property color yarn: Theme.accent

    // Shoots out from its corner when it first appears
    property real unspool: 0
    NumberAnimation on unspool {
        id: unspoolAnimation
        from: 0
        to: 1
        duration: 280
        easing.type: Easing.OutCubic
    }

    onVisibleChanged: {
        if (visible) unspoolAnimation.restart()
    }

    property real clock: 0
    property real velocity1x: 0
    property real velocity1y: 0
    property real velocity2x: 0
    property real velocity2y: 0

    function step(seconds) {
        clock += seconds

        var dx = p3.x - p0.x
        var dy = p3.y - p0.y
        var distance = Math.sqrt(dx * dx + dy * dy)
        var slack = Math.sqrt(Math.max(reach * reach - distance * distance, 0))
        var sag = Math.min(maxSag, minSag + slack * 0.14) * Math.min(unspool * 1.2, 1)
        var sway = Math.sin(clock * 1.3 + phase) * swayPixels

        velocity1x += (stiffness * (p0.x + dx / 3 + sway - p1.x) - damping * velocity1x) * seconds
        velocity1y += (stiffness * (p0.y + dy / 3 + sag - p1.y) - damping * velocity1y) * seconds
        velocity2x += (stiffness * (p0.x + dx * 2 / 3 - sway - p2.x) - damping * velocity2x) * seconds
        velocity2y += (stiffness * (p0.y + dy * 2 / 3 + sag - p2.y) - damping * velocity2y) * seconds

        p1 = Qt.point(p1.x + velocity1x * seconds, p1.y + velocity1y * seconds)
        p2 = Qt.point(p2.x + velocity2x * seconds, p2.y + velocity2y * seconds)

        strandLength = hop(p0, p1) + hop(p1, p2) + hop(p2, p3)
    }

    function hop(a, b) {
        return Math.sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y))
    }

    FrameAnimation {
        running: strand.visible
        // A long frame would make the swing jump
        onTriggered: strand.step(Math.min(frameTime, 1 / 30))
    }

    mesh: GridMesh {
        resolution: Qt.size(64, 1)
    }

    vertexShader: "file://" + Quickshell.shellDir + "/shaders/yarn.vert.qsb"
    fragmentShader: "file://" + Quickshell.shellDir + "/shaders/yarn.frag.qsb"
}
