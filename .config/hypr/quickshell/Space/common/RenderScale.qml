pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    property real scale: 1
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
        if (++frames < 16) return
        const ms = (now - begin) / frames
        begin = now
        frames = 0
        if (!settled) return settled = true
        if (ms > 24) scale = Math.max(0.5, scale - 0.15)
        else if (ms < 17) scale = Math.min(1, scale + 0.15)
    }
    function size(w, h, screen) {
        if (scale >= 1) return Qt.size(0, 0)
        const k = scale * (Hyprland.monitorFor(screen)?.scale ?? 1)
        return Qt.size(Math.ceil(w * k), Math.ceil(h * k))
    }
}
