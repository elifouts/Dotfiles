pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real value: 1
    property bool has: false

    function probe() { probeProc.running = true }
    function set(v) {
        value = v
        apply.restart()
    }

    Process {
        id: probeProc
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | head -n1 | cut -d, -f4 | tr -d %"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text)
                root.has = !isNaN(v)
                if (root.has) root.value = v / 100
            }
        }
    }
    Timer {
        id: apply
        interval: 50
        onTriggered: Quickshell.execDetached(["brightnessctl", "-q", "set", Math.max(1, Math.round(root.value * 100)) + "%"])
    }
}
