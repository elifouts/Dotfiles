pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root
    property real scale: 1
    property real next: 1
    property real last: 0
    property real begin: 0
    property int frames: 0
    property bool settled: false

    function frame() {
        const now = Date.now()
        if (now - last > 120) {
            begin = now
            frames = 0
            settled = false
        }
        last = now
        idle.restart()
        if (++frames < 16) return
        const ms = (now - begin) / frames
        begin = now
        frames = 0
        if (!settled) return settled = true
        if (ms > 24) next = Math.max(0.5, next - 0.15)
        else if (ms < 17) next = Math.min(1, next + 0.15)
    }
    Timer { id: idle; interval: 250; onTriggered: root.scale = root.next }
    function size(w, h, screen) {
        if (scale >= 1) return Qt.size(0, 0)
        const k = scale * (Hyprland.monitorFor(screen)?.scale ?? 1)
        return Qt.size(Math.ceil(w * k), Math.ceil(h * k))
    }
}
