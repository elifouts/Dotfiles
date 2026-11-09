import QtQuick

FrameAnimation {
    id: pace

    property real duration: 1000
    property real delay: 0
    property var curve: null
    property real from: 0
    property real to: 1
    property real value: 0
    property real elapsed: 0
    property var clock: null
    property real frameMs: 0
    property real wall: 0
    property real seen: 0
    signal began()
    signal done()

    function play() {
        elapsed = 0
        wall = 0
        seen = 0
        value = from
        began()
        restart()
    }
    function ease(u) {
        if (!curve || u <= 0 || u >= 1) return u
        const [x1, y1, x2, y2] = curve, ax = 1 - 3 * x2 + 3 * x1, bx = 3 * x2 - 6 * x1, cx = 3 * x1
        let t = u
        for (let i = 0; i < 8; i++) {
            const x = ((ax * t + bx) * t + cx) * t - u, d = (3 * ax * t + 2 * bx) * t + cx
            if (Math.abs(x) < 1e-6 || Math.abs(d) < 1e-6) break
            t = Math.max(0, Math.min(1, t - x / d))
        }
        return ((1 - 3 * y2 + 3 * y1) * t + 3 * y2 - 6 * y1) * t * t + 3 * y1 * t
    }
    function advance(onFrame) {
        const f = frameMs > 0 ? frameMs : 16.7, dt = wall - seen
        seen = wall
        let step = Math.min(dt, Math.max(f * 2, 12))
        if (onFrame && Math.abs(dt - f) < f * 0.5) step = f
        elapsed += step
        const u = Math.max(0, Math.min(1, (elapsed - delay) / Math.max(1, duration)))
        value = from + (to - from) * ease(u)
        if (u < 1) return
        stop()
        done()
    }
    property Connections watch: Connections {
        target: pace.running ? pace.clock : null
        function onAfterSynchronizing() { pace.advance(true) }
    }
    onTriggered: {
        wall += frameTime * 1000
        if (!clock || wall - seen > Math.max(frameMs * 2.5, 30)) advance(false)
    }
}
