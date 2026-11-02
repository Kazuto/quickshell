import QtQuick
import "root:/"

// The one outline everything lives in. Changing viewKey runs the design's
// motion: content fades out, the outline morphs to the new view's size, new
// content fades in. Only the outline animates size; children never scale.
Rectangle {
    id: surface

    property string viewKey: ""
    property var views: ({})      // viewKey -> Component
    readonly property Item view: loader.item

    // Which curve the next geometry change uses, picked from where it is heading
    property string motion: "width"
    property real lastTargetHeight: 0
    property bool ready: false

    readonly property int motionMs: motion === "open" ? Config.morphOpenMs
        : motion === "close" ? Config.morphCloseMs
        : Config.widthChangeMs
    readonly property var motionCurve: motion === "open" ? Config.curveSpring
        : motion === "close" ? Config.curveEaseIn
        : Config.curveEaseOut

    color: Theme.island
    border.width: 1
    border.color: Theme.stroke
    clip: true

    function sync() {
        var item = loader.item
        if (!item) return

        var targetHeight = item.implicitHeight
        if (targetHeight > lastTargetHeight + 0.5) motion = "open"
        else if (targetHeight < lastTargetHeight - 0.5) motion = "close"
        else motion = "width"
        lastTargetHeight = targetHeight

        radius = item.cornerRadius !== undefined ? item.cornerRadius : targetHeight / 2
        height = targetHeight
        width = item.implicitWidth
    }

    function commit() {
        loader.sourceComponent = views[viewKey] || null
        sync()
    }

    onViewKeyChanged: {
        if (ready) swap.restart()
    }

    Component.onCompleted: {
        commit()
        loader.opacity = 1
        ready = true
    }

    Behavior on width {
        enabled: surface.ready
        NumberAnimation {
            duration: surface.motionMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: surface.motionCurve
        }
    }

    Behavior on height {
        enabled: surface.ready
        NumberAnimation {
            duration: surface.motionMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: surface.motionCurve
        }
    }

    Behavior on radius {
        enabled: surface.ready
        NumberAnimation {
            duration: surface.motionMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: surface.motionCurve
        }
    }

    SequentialAnimation {
        id: swap

        NumberAnimation {
            target: loader
            property: "opacity"
            to: 0
            duration: Config.contentFadeOutMs
            easing.type: Easing.OutQuad
        }
        ScriptAction {
            script: surface.commit()
        }
        PauseAnimation {
            duration: Config.contentFadeInDelayMs
        }
        NumberAnimation {
            target: loader
            property: "opacity"
            to: 1
            duration: Config.contentFadeInMs
            easing.type: Easing.OutQuad
        }
    }

    Loader {
        id: loader
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: 0
    }

    // A view can change size on its own: longer titles, filtered lists
    Connections {
        target: loader.item
        ignoreUnknownSignals: true
        function onImplicitWidthChanged() { surface.sync() }
        function onImplicitHeightChanged() { surface.sync() }
    }
}
