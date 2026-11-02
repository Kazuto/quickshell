pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// One sampler for everything graphed, so all histories cover the same window
Singleton {
    id: root

    readonly property int sampleMs: 3000
    readonly property int windowSeconds: 60
    readonly property int windowSamples: windowSeconds * 1000 / sampleMs

    property int cpuUsage: 0
    property int memoryUsage: 0
    property int gpuUsage: 0
    property string networkSpeedDown: "0 B/s"
    property string networkSpeedUp: "0 B/s"
    property int cpuTemp: 0
    property int gpuTemp: 0
    property int nvmeTemp: 0

    property var cpuHistory: []
    property var memoryHistory: []
    property var gpuHistory: []

    property real lastCpuTotal: 0
    property real lastCpuIdle: 0
    property real lastRx: -1
    property real lastTx: -1
    property real lastNetAt: 0

    function formatRate(bytesPerSecond) {
        if (bytesPerSecond >= 1048576) return (bytesPerSecond / 1048576).toFixed(1) + " MB/s"
        if (bytesPerSecond >= 1024) return Math.round(bytesPerSecond / 1024) + " KB/s"
        return Math.round(bytesPerSecond) + " B/s"
    }

    function addToHistory(array, value) {
        return array.concat([value]).slice(-windowSamples)
    }

    Process {
        id: sampleProcess
        running: true
        command: ["sh", "-c", `
            read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
            echo "CPU:$((user + nice + system + idle + iowait + irq + softirq + steal)):$((idle + iowait))"
            free | awk '/^Mem:/{print "MEM:" int($3 / $2 * 100)}'
            echo "GPU:$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1)"
            IFACE=$(ip route show default | awk 'NR==1{print $5}')
            [ -n "$IFACE" ] && echo "NET:$(cat /sys/class/net/$IFACE/statistics/rx_bytes):$(cat /sys/class/net/$IFACE/statistics/tx_bytes)"
        `]

        stdout: SplitParser {
            onRead: line => {
                var parts = line.trim().split(":")
                if (parts[0] === "CPU") {
                    var total = parseFloat(parts[1])
                    var idle = parseFloat(parts[2])
                    if (root.lastCpuTotal > 0 && total > root.lastCpuTotal) {
                        var busy = 1 - (idle - root.lastCpuIdle) / (total - root.lastCpuTotal)
                        root.cpuUsage = Math.round(busy * 100)
                        root.cpuHistory = root.addToHistory(root.cpuHistory, root.cpuUsage)
                    }
                    root.lastCpuTotal = total
                    root.lastCpuIdle = idle
                } else if (parts[0] === "MEM") {
                    root.memoryUsage = parseInt(parts[1], 10) || 0
                    root.memoryHistory = root.addToHistory(root.memoryHistory, root.memoryUsage)
                } else if (parts[0] === "GPU") {
                    root.gpuUsage = parseInt(parts[1], 10) || 0
                    root.gpuHistory = root.addToHistory(root.gpuHistory, root.gpuUsage)
                } else if (parts[0] === "NET") {
                    var rx = parseFloat(parts[1])
                    var tx = parseFloat(parts[2])
                    var now = Date.now()
                    if (root.lastRx >= 0 && rx >= root.lastRx && tx >= root.lastTx) {
                        var seconds = (now - root.lastNetAt) / 1000
                        root.networkSpeedDown = root.formatRate((rx - root.lastRx) / seconds)
                        root.networkSpeedUp = root.formatRate((tx - root.lastTx) / seconds)
                    }
                    root.lastRx = rx
                    root.lastTx = tx
                    root.lastNetAt = now
                }
            }
        }
    }

    Timer {
        interval: root.sampleMs
        running: true
        repeat: true
        onTriggered: {
            sampleProcess.running = false
            sampleProcess.running = true
        }
    }

    // Temperature monitoring
    Process {
        id: tempProcess
        running: true
        command: ["sh", "-c", `
            # CPU temp (k10temp Tctl)
            CPU_TEMP=$(sensors | grep "Tctl:" | head -1 | awk '{gsub(/[^0-9.]/, "", \$2); print int(\$2+0.5)}')
            # GPU temp (amdgpu edge)
            GPU_TEMP=$(sensors | grep "edge:" | head -1 | awk '{gsub(/[^0-9.]/, "", \$2); print int(\$2+0.5)}')
            # NVMe temp
            NVME_TEMP=$(sensors | grep "Composite:" | head -1 | awk '{gsub(/[^0-9.]/, "", \$2); print int(\$2+0.5)}')

            echo "CPU:\${CPU_TEMP:-0}"
            echo "GPU:\${GPU_TEMP:-0}"
            echo "NVME:\${NVME_TEMP:-0}"
        `]

        stdout: SplitParser {
            onRead: data => {
                var trimmed = data.trim()

                if (trimmed.startsWith("CPU:"))  { cpuTemp  = parseInt(trimmed.substring(4)) || 0; return }
                if (trimmed.startsWith("GPU:"))  { gpuTemp  = parseInt(trimmed.substring(4)) || 0; return }
                if (trimmed.startsWith("NVME:")) { nvmeTemp = parseInt(trimmed.substring(5)) || 0 }
            }
        }
    }

    Timer {
        interval: 5000  // Update every 5 seconds
        running: true
        repeat: true
        onTriggered: {
            tempProcess.running = false
            tempProcess.running = true
        }
    }
}
