import QtQuick
import "../style/common"

Item {
    id: m

    property real t: 0
    property bool active: false
    property bool leaving: false
    property int openMs: 520
    property int closeMs: 320
    property var openCurve: Theme.settle
    property var closeCurve: Theme.leave
    property bool sideways: false
    property bool fadeOut: true
    signal opened()
    signal closed()

    function clamp(v) { return Math.max(0, Math.min(1, v)) }
    function grow(from, span) { return Math.max(0, Math.min(1.02, (t - from) / span)) }
    readonly property real rise: clamp(t / 0.28)
    readonly property real mw: sideways ? grow(0.32, 0.68) : grow(0.12, 0.48)
    readonly property real mh: sideways ? grow(0.12, 0.48) : grow(0.32, 0.68)
    function stage(from) { return clamp(leaving && fadeOut ? (t - 0.7) / 0.3 : (t - from) / (1 - from)) }

    function open() { leaving = false; active = true; to(1) }
    function close() { if (!active || leaving) return; leaving = true; to(0) }
    function reset() { tween.stop(); active = leaving = false; t = 0 }
    function to(v) {
        tween.stop()
        tween.to = v
        tween.duration = Theme.ms(v === 1 ? openMs : closeMs)
        tween.easing.bezierCurve = v === 1 ? openCurve : closeCurve
        tween.start()
    }

    NumberAnimation {
        id: tween
        target: m
        property: "t"
        easing.type: Easing.BezierSpline
        onFinished: {
            if (!m.leaving) return m.opened()
            m.active = false
            m.leaving = false
            m.closed()
        }
    }
}
