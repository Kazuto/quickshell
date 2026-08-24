pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property int cpuUsage: 0
    property int memoryUsage: 0
    property int gpuUsage: 0
    property string networkSpeedDown: "0b/s"
    property string networkSpeedUp: "0b/s"
    property real networkBitsPerSecDown: 0
    property real networkBitsPerSecUp: 0
    property int cpuTemp: 0
    property int gpuTemp: 0
    property int nvmeTemp: 0

    function formatSpeed(bits) {
        if (bits >= 1000000000) {
            return (bits / 1000000000).toFixed(1) + "Gb/s"
        } else if (bits >= 1000000) {
            return (bits / 1000000).toFixed(1) + "Mb/s"
        } else if (bits >= 1000) {
            return (bits / 1000).toFixed(1) + "Kb/s"
        } else {
            return Math.round(bits) + "b/s"
        }
    }

    // History arrays (last 60 samples)
    property var cpuHistory: []
    property var memoryHistory: []
    property var gpuHistory: []
    property var networkHistoryDown: []
    property var networkHistoryUp: []

    function addToHistory(array, value, maxLength) {
        var newArray = array.slice()
        newArray.push(value)
        if (newArray.length > maxLength) {
            newArray.shift()
        }
        return newArray
    }

    // CPU Usage
    Process {
        id: cpuProcess
        running: true
        command: ["sh", "-c", "top -bn2 -d 0.5 | grep 'Cpu(s)' | tail -1 | awk '{print int($2)}'"]

        stdout: SplitParser {
            onRead: data => {
                cpuUsage = parseInt(data) || 0
                cpuHistory = addToHistory(cpuHistory, cpuUsage, 60)
            }
        }
    }

    Timer {
        interval: 10000  // Update every 10 seconds
        running: true
        repeat: true
        onTriggered: {
            cpuProcess.running = false
            cpuProcess.running = true
        }
    }

    // Memory Usage
    Process {
        id: memoryProcess
        running: true
        command: ["sh", "-c", "free | grep Mem | awk '{print int($3/$2 * 100)}'"]

        stdout: SplitParser {
            onRead: data => {
                memoryUsage = parseInt(data) || 0
                memoryHistory = addToHistory(memoryHistory, memoryUsage, 60)
            }
        }
    }

    Timer {
        interval: 30000  // Update every 30 seconds
        running: true
        repeat: true
        onTriggered: {
            memoryProcess.running = false
            memoryProcess.running = true
        }
    }

    // GPU Usage
    Process {
        id: gpuProcess
        running: true
        command: ["sh", "-c", `
            # Try to read GPU usage from amdgpu sysfs
            if [ -f /sys/class/drm/card0/device/gpu_busy_percent ]; then
                cat /sys/class/drm/card0/device/gpu_busy_percent
            else
                # Fallback: estimate from sensors power usage (rough approximation)
                # Max power is 170W based on your GPU
                POWER=$(sensors amdgpu-pci-0c00 2>/dev/null | grep PPT | awk '{print int(\$2)}')
                if [ -n "\$POWER" ]; then
                    echo \$(( POWER * 100 / 170 ))
                else
                    echo 0
                fi
            fi
        `]

        stdout: SplitParser {
            onRead: data => {
                gpuUsage = parseInt(data) || 0
                gpuHistory = addToHistory(gpuHistory, gpuUsage, 60)
            }
        }
    }

    Timer {
        interval: 5000  // Update every 5 seconds
        running: true
        repeat: true
        onTriggered: {
            gpuProcess.running = false
            gpuProcess.running = true
        }
    }

    // Network Speed (RX and TX)
    Process {
        id: networkProcess
        running: true
        command: ["sh", "-c", `
            PREV_FILE="/tmp/quickshell_net_prev"
            CURRENT_RX=$(cat /sys/class/net/enp6s0/statistics/rx_bytes)
            CURRENT_TX=$(cat /sys/class/net/enp6s0/statistics/tx_bytes)

            if [ -f "$PREV_FILE" ]; then
                PREV_RX=$(head -1 "$PREV_FILE")
                PREV_TX=$(tail -1 "$PREV_FILE")

                RX_DIFF=$((CURRENT_RX - PREV_RX))
                TX_DIFF=$((CURRENT_TX - PREV_TX))

                RX_BYTES_PER_SEC=$((RX_DIFF / 5))
                TX_BYTES_PER_SEC=$((TX_DIFF / 5))

                RX_BITS=$((RX_BYTES_PER_SEC * 8))
                TX_BITS=$((TX_BYTES_PER_SEC * 8))

                echo "RX:$RX_BITS"
                echo "TX:$TX_BITS"
            else
                echo "RX:0"
                echo "TX:0"
            fi

            echo "$CURRENT_RX" > "$PREV_FILE"
            echo "$CURRENT_TX" >> "$PREV_FILE"
        `]

        stdout: SplitParser {
            onRead: data => {
                var trimmed = data.trim()

                // Parse RX bits
                if (trimmed.startsWith("RX:")) {
                    var value = trimmed.substring(3)
                    var num = parseFloat(value)
                    if (!isNaN(num)) {
                        networkBitsPerSecDown = num
                        networkSpeedDown = formatSpeed(num)
                        networkHistoryDown = addToHistory(networkHistoryDown, num / 1000000, 60)
                    }
                }
                // Parse TX bits
                else if (trimmed.startsWith("TX:")) {
                    var value = trimmed.substring(3)
                    var num = parseFloat(value)
                    if (!isNaN(num)) {
                        networkBitsPerSecUp = num
                        networkSpeedUp = formatSpeed(num)
                        networkHistoryUp = addToHistory(networkHistoryUp, num / 1000000, 60)
                    }
                }
            }
        }
    }

    Timer {
        interval: 5000  // Update every 5 seconds
        running: true
        repeat: true
        onTriggered: {
            networkProcess.running = false
            networkProcess.running = true
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

                if (trimmed.startsWith("CPU:")) {
                    cpuTemp = parseInt(trimmed.substring(4)) || 0
                }
                else if (trimmed.startsWith("GPU:")) {
                    gpuTemp = parseInt(trimmed.substring(4)) || 0
                }
                else if (trimmed.startsWith("NVME:")) {
                    nvmeTemp = parseInt(trimmed.substring(5)) || 0
                }
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
