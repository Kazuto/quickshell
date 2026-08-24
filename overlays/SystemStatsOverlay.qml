import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/singletons"

PanelWindow {
    id: systemStatsOverlay

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: AppState.toggleSystemStatsOverlay()
        z: -1
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 12
            rightMargin: 20
        }
        width: 400
        height: 750
        color: Config.alpha(Theme.base, 0.95)
        radius: Config.overlayRadius
        border.color: Theme.surface0
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Column {
            anchors {
                fill: parent
                margins: 20
            }
            spacing: 20

            // Header
            Text {
                text: "System Monitor"
                color: Theme.text
                font.pixelSize: 18
                font.bold: true
                font.family: Config.moduleFontFamily
            }

            // CPU Section
            Column {
                width: parent.width
                spacing: 10

                Item {
                    width: parent.width
                    height: 20

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: Icon.cpu + " CPU"
                        color: Theme.sky
                        font.pixelSize: 14
                        font.bold: true
                        font.family: Config.moduleFontFamily
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Text {
                            text: SystemStatsData.cpuTemp + "°C"
                            color: SystemStatsData.cpuTemp >= 80 ? Theme.red : SystemStatsData.cpuTemp >= 70 ? Theme.peach : Theme.sky
                            font.pixelSize: 14
                            font.bold: true
                            font.family: Config.moduleFontFamily
                        }

                        Text {
                            text: SystemStatsData.cpuUsage + "%"
                            color: SystemStatsData.cpuUsage >= 80 ? Theme.red : Theme.sky
                            font.pixelSize: 14
                            font.bold: true
                            font.family: Config.moduleFontFamily
                        }
                    }
                }

                Canvas {
                    id: cpuCanvas
                    width: parent.width
                    height: 80

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        if (SystemStatsData.cpuHistory.length < 2) return

                        // Draw grid
                        ctx.strokeStyle = Theme.surface1
                        ctx.lineWidth = 1
                        for (var i = 0; i <= 4; i++) {
                            var y = (i / 4) * height
                            ctx.beginPath()
                            ctx.moveTo(0, y)
                            ctx.lineTo(width, y)
                            ctx.stroke()
                        }

                        // Draw area fill
                        ctx.fillStyle = Config.alpha(Theme.sky, 0.2)
                        ctx.beginPath()
                        ctx.moveTo(0, height)

                        for (var j = 0; j < SystemStatsData.cpuHistory.length; j++) {
                            var x = (j / (SystemStatsData.cpuHistory.length - 1)) * width
                            var val = SystemStatsData.cpuHistory[j]
                            var y = height - (val / 100) * height
                            if (j === 0) ctx.lineTo(x, y)
                            else ctx.lineTo(x, y)
                        }

                        ctx.lineTo(width, height)
                        ctx.closePath()
                        ctx.fill()

                        // Draw line
                        ctx.strokeStyle = Theme.sky
                        ctx.lineWidth = 2
                        ctx.beginPath()

                        for (var k = 0; k < SystemStatsData.cpuHistory.length; k++) {
                            var x2 = (k / (SystemStatsData.cpuHistory.length - 1)) * width
                            var val2 = SystemStatsData.cpuHistory[k]
                            var y2 = height - (val2 / 100) * height
                            if (k === 0) ctx.moveTo(x2, y2)
                            else ctx.lineTo(x2, y2)
                        }

                        ctx.stroke()
                    }

                    Connections {
                        target: SystemStatsData
                        function onCpuHistoryChanged() {
                            cpuCanvas.requestPaint()
                        }
                    }
                }
            }

            // GPU Section
            Column {
                width: parent.width
                spacing: 10

                Item {
                    width: parent.width
                    height: 20

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "🎮 GPU"
                        color: Theme.mauve
                        font.pixelSize: 14
                        font.bold: true
                        font.family: Config.moduleFontFamily
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Text {
                            text: SystemStatsData.gpuTemp + "°C"
                            color: SystemStatsData.gpuTemp >= 85 ? Theme.red : SystemStatsData.gpuTemp >= 75 ? Theme.peach : Theme.mauve
                            font.pixelSize: 14
                            font.bold: true
                            font.family: Config.moduleFontFamily
                        }

                        Text {
                            text: SystemStatsData.gpuUsage + "%"
                            color: SystemStatsData.gpuUsage >= 90 ? Theme.red : Theme.mauve
                            font.pixelSize: 14
                            font.bold: true
                            font.family: Config.moduleFontFamily
                        }
                    }
                }

                Canvas {
                    id: gpuCanvas
                    width: parent.width
                    height: 80

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        if (SystemStatsData.gpuHistory.length < 2) return

                        // Draw grid
                        ctx.strokeStyle = Theme.surface1
                        ctx.lineWidth = 1
                        for (var i = 0; i <= 4; i++) {
                            var y = (i / 4) * height
                            ctx.beginPath()
                            ctx.moveTo(0, y)
                            ctx.lineTo(width, y)
                            ctx.stroke()
                        }

                        // Draw area fill
                        ctx.fillStyle = Config.alpha(Theme.mauve, 0.2)
                        ctx.beginPath()
                        ctx.moveTo(0, height)

                        for (var j = 0; j < SystemStatsData.gpuHistory.length; j++) {
                            var x = (j / (SystemStatsData.gpuHistory.length - 1)) * width
                            var val = SystemStatsData.gpuHistory[j]
                            var y = height - (val / 100) * height
                            if (j === 0) ctx.lineTo(x, y)
                            else ctx.lineTo(x, y)
                        }

                        ctx.lineTo(width, height)
                        ctx.closePath()
                        ctx.fill()

                        // Draw line
                        ctx.strokeStyle = Theme.mauve
                        ctx.lineWidth = 2
                        ctx.beginPath()

                        for (var k = 0; k < SystemStatsData.gpuHistory.length; k++) {
                            var x2 = (k / (SystemStatsData.gpuHistory.length - 1)) * width
                            var val2 = SystemStatsData.gpuHistory[k]
                            var y2 = height - (val2 / 100) * height
                            if (k === 0) ctx.moveTo(x2, y2)
                            else ctx.lineTo(x2, y2)
                        }

                        ctx.stroke()
                    }

                    Connections {
                        target: SystemStatsData
                        function onGpuHistoryChanged() {
                            gpuCanvas.requestPaint()
                        }
                    }
                }
            }

            // Memory Section
            Column {
                width: parent.width
                spacing: 10

                Item {
                    width: parent.width
                    height: 20

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: Icon.memory + " Memory"
                        color: Theme.green
                        font.pixelSize: 14
                        font.bold: true
                        font.family: Config.moduleFontFamily
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: SystemStatsData.memoryUsage + "%"
                        color: SystemStatsData.memoryUsage >= 80 ? Theme.red : Theme.green
                        font.pixelSize: 14
                        font.bold: true
                        font.family: Config.moduleFontFamily
                    }
                }

                Canvas {
                    id: memoryCanvas
                    width: parent.width
                    height: 80

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        if (SystemStatsData.memoryHistory.length < 2) return

                        // Draw grid
                        ctx.strokeStyle = Theme.surface1
                        ctx.lineWidth = 1
                        for (var i = 0; i <= 4; i++) {
                            var y = (i / 4) * height
                            ctx.beginPath()
                            ctx.moveTo(0, y)
                            ctx.lineTo(width, y)
                            ctx.stroke()
                        }

                        // Draw area fill
                        ctx.fillStyle = Config.alpha(Theme.green, 0.2)
                        ctx.beginPath()
                        ctx.moveTo(0, height)

                        for (var j = 0; j < SystemStatsData.memoryHistory.length; j++) {
                            var x = (j / (SystemStatsData.memoryHistory.length - 1)) * width
                            var val = SystemStatsData.memoryHistory[j]
                            var y = height - (val / 100) * height
                            if (j === 0) ctx.lineTo(x, y)
                            else ctx.lineTo(x, y)
                        }

                        ctx.lineTo(width, height)
                        ctx.closePath()
                        ctx.fill()

                        // Draw line
                        ctx.strokeStyle = Theme.green
                        ctx.lineWidth = 2
                        ctx.beginPath()

                        for (var k = 0; k < SystemStatsData.memoryHistory.length; k++) {
                            var x2 = (k / (SystemStatsData.memoryHistory.length - 1)) * width
                            var val2 = SystemStatsData.memoryHistory[k]
                            var y2 = height - (val2 / 100) * height
                            if (k === 0) ctx.moveTo(x2, y2)
                            else ctx.lineTo(x2, y2)
                        }

                        ctx.stroke()
                    }

                    Connections {
                        target: SystemStatsData
                        function onMemoryHistoryChanged() {
                            memoryCanvas.requestPaint()
                        }
                    }
                }
            }

            // Network Section
            Column {
                width: parent.width
                spacing: 10

                Item {
                    width: parent.width
                    height: 20

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: Icon.network + " Network"
                        color: Theme.mauve
                        font.pixelSize: 14
                        font.bold: true
                        font.family: Config.moduleFontFamily
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            text: Icon.downArrow + " " + SystemStatsData.networkSpeedDown
                            color: Theme.sky
                            font.pixelSize: 12
                            font.family: Config.moduleFontFamily
                        }

                        Text {
                            text: Icon.upArrow + " " + SystemStatsData.networkSpeedUp
                            color: Theme.peach
                            font.pixelSize: 12
                            font.family: Config.moduleFontFamily
                        }
                    }
                }

                Canvas {
                    id: networkCanvas
                    width: parent.width
                    height: 80

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        var rxHistory = SystemStatsData.networkHistoryDown
                        var txHistory = SystemStatsData.networkHistoryUp

                        if (rxHistory.length < 2 && txHistory.length < 2) return

                        // Find max value for scaling across both
                        var maxVal = 1
                        for (var m = 0; m < rxHistory.length; m++) {
                            if (rxHistory[m] > maxVal) maxVal = rxHistory[m]
                        }
                        for (var n = 0; n < txHistory.length; n++) {
                            if (txHistory[n] > maxVal) maxVal = txHistory[n]
                        }

                        // Draw grid
                        ctx.strokeStyle = Theme.surface1
                        ctx.lineWidth = 1
                        for (var i = 0; i <= 4; i++) {
                            var y = (i / 4) * height
                            ctx.beginPath()
                            ctx.moveTo(0, y)
                            ctx.lineTo(width, y)
                            ctx.stroke()
                        }

                        // Draw RX (download) - blue
                        if (rxHistory.length >= 2) {
                            // Area fill
                            ctx.fillStyle = Config.alpha(Theme.sky, 0.2)
                            ctx.beginPath()
                            ctx.moveTo(0, height)

                            for (var j = 0; j < rxHistory.length; j++) {
                                var x = (j / (rxHistory.length - 1)) * width
                                var val = rxHistory[j]
                                var y = height - (val / maxVal) * height
                                ctx.lineTo(x, y)
                            }

                            ctx.lineTo(width, height)
                            ctx.closePath()
                            ctx.fill()

                            // Line
                            ctx.strokeStyle = Theme.sky
                            ctx.lineWidth = 2
                            ctx.beginPath()

                            for (var k = 0; k < rxHistory.length; k++) {
                                var x2 = (k / (rxHistory.length - 1)) * width
                                var val2 = rxHistory[k]
                                var y2 = height - (val2 / maxVal) * height
                                if (k === 0) ctx.moveTo(x2, y2)
                                else ctx.lineTo(x2, y2)
                            }

                            ctx.stroke()
                        }

                        // Draw TX (upload) - orange/peach
                        if (txHistory.length >= 2) {
                            // Line only (no fill to keep it visible)
                            ctx.strokeStyle = Theme.peach
                            ctx.lineWidth = 2
                            ctx.beginPath()

                            for (var p = 0; p < txHistory.length; p++) {
                                var x3 = (p / (txHistory.length - 1)) * width
                                var val3 = txHistory[p]
                                var y3 = height - (val3 / maxVal) * height
                                if (p === 0) ctx.moveTo(x3, y3)
                                else ctx.lineTo(x3, y3)
                            }

                            ctx.stroke()
                        }
                    }

                    Connections {
                        target: SystemStatsData
                        function onNetworkHistoryDownChanged() {
                            networkCanvas.requestPaint()
                        }
                        function onNetworkHistoryUpChanged() {
                            networkCanvas.requestPaint()
                        }
                    }
                }
            }

            // Temperatures Section
            Column {
                width: parent.width
                spacing: 10

                Text {
                    text: "🌡 Storage Temperature"
                    color: Theme.peach
                    font.pixelSize: 14
                    font.bold: true
                    font.family: Config.moduleFontFamily
                }

                Column {
                    width: parent.width
                    spacing: 8

                    // NVMe Temperature
                    Item {
                        width: parent.width
                        height: 18

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "NVMe SSD"
                            color: Theme.subtext0
                            font.pixelSize: 12
                            font.family: Config.moduleFontFamily
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: SystemStatsData.nvmeTemp + "°C"
                            color: SystemStatsData.nvmeTemp >= 70 ? Theme.red : SystemStatsData.nvmeTemp >= 60 ? Theme.peach : Theme.green
                            font.pixelSize: 12
                            font.bold: true
                            font.family: Config.moduleFontFamily
                        }
                    }
                }
            }
        }
    }
}
