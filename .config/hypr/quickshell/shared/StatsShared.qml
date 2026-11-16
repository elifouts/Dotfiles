import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: st
    property bool running: true
    property int interval: 1500
    property var s: ({})
    property var last: [0, 0]
    property real cpu: 0
    readonly property real ram: s.MemTotal ? 1 - s.MemAvailable / s.MemTotal : 0
    readonly property var gpu: (s.GPU || "").split(",").map(x => x.trim())
    function gb(used, total, div) { return (used / div).toFixed(1) + " / " + (total / div).toFixed(1) + " GB" }
    function uptime(sec) {
        const d = Math.floor(sec / 86400), h = Math.floor(sec % 86400 / 3600), m = Math.floor(sec % 3600 / 60)
        return (d ? d + "d " : "") + h + "h " + m + "m"
    }

    Component.onCompleted: if (running) poll.running = true
    Timer { interval: st.interval; running: st.running; repeat: true; onTriggered: if (!poll.running) poll.running = true }
    Process {
        id: poll
        command: [Quickshell.shellPath("shared/stats.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {}
                for (const l of text.split("\n")) {
                    const i = l.indexOf(" ")
                    if (l.startsWith("cpu ")) {
                        const n = l.trim().split(/\s+/).slice(1).map(Number), tot = n.reduce((a, b) => a + b, 0), idle = n[3] + n[4]
                        if (st.last[0]) st.cpu = 1 - (idle - st.last[1]) / Math.max(1, tot - st.last[0])
                        st.last = [tot, idle]
                    } else if (l.includes(":")) o[l.split(":")[0]] = parseInt(l.split(":")[1])
                    else if (i > 0) o[l.slice(0, i)] = l.slice(i + 1)
                }
                st.s = o
            }
        }
    }
}
