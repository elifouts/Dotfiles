pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu: 0
    property real ram: 0
    property string net: "--"
    property var last: [0, 0]

    FileView { id: stat; path: "/proc/stat"; printErrors: false }
    FileView { id: mem; path: "/proc/meminfo"; printErrors: false }
    FileView { id: route; path: "/proc/net/route"; printErrors: false }
    FileView { id: wifi; path: "/proc/net/wireless"; printErrors: false }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload(); mem.reload(); route.reload(); wifi.reload()
            const n = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            const total = n.reduce((a, b) => a + b, 0), idle = n[3] + n[4]
            if (root.last[0]) root.cpu = 1 - (idle - root.last[1]) / Math.max(1, total - root.last[0])
            root.last = [total, idle]
            const kb = k => Number((mem.text().match(new RegExp(k + ":\\s+(\\d+)")) || [0, 0])[1])
            root.ram = 1 - kb("MemAvailable") / Math.max(1, kb("MemTotal"))
            const dev = (route.text().split("\n").find(l => l.split("\t")[1] === "00000000") || "").split("\t")[0]
            root.net = !dev ? "OFFLINE" : wifi.text().includes(dev + ":") ? "WLAN" : "LINK"
        }
    }
}
