import QtQuick
import "../style/common"

Item {
    id: plot

    property var curve: [0.15, 0.85, 0.25, 1]
    property real t: 0
    property real p: 0
    property bool playing: false
    signal edited(var curve)
    signal resetRequested()

    readonly property real yMin: -0.5
    readonly property real yMax: 1.5
    readonly property real inset: 14

    function px(x) { return inset + x * (width - inset * 2) }
    function py(y) { return inset + (1 - (y - yMin) / (yMax - yMin)) * (height - inset * 2) }
    function fromX(sx) { return Math.max(0, Math.min(1, (sx - inset) / (width - inset * 2))) }
    function fromY(sy) { return Math.max(yMin, Math.min(yMax, yMin + (1 - (sy - inset) / (height - inset * 2)) * (yMax - yMin))) }

    onCurveChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Rectangle {
        anchors.fill: parent
        radius: Theme.r(12)
        color: Theme.alpha(Theme.fg, 0.045)
        border.width: Theme.lines
        border.color: Theme.edge
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        Connections {
            target: Theme
            function onAccentChanged() { canvas.requestPaint() }
            function onFgChanged() { canvas.requestPaint() }
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const c = plot.curve
            const fg = Theme.fg
            const rgba = (col, a) => "rgba(" + Math.round(col.r * 255) + "," + Math.round(col.g * 255) + "," + Math.round(col.b * 255) + "," + a + ")"

            ctx.lineWidth = 1
            for (let i = 0; i <= 4; i++) {
                const x = Math.round(plot.px(i / 4)) + 0.5
                ctx.strokeStyle = rgba(fg, 0.07)
                ctx.beginPath(); ctx.moveTo(x, plot.inset); ctx.lineTo(x, height - plot.inset); ctx.stroke()
            }
            for (const y of [0, 1]) {
                const sy = Math.round(plot.py(y)) + 0.5
                ctx.strokeStyle = rgba(fg, 0.22)
                ctx.setLineDash([3, 4])
                ctx.beginPath(); ctx.moveTo(plot.inset, sy); ctx.lineTo(width - plot.inset, sy); ctx.stroke()
                ctx.setLineDash([])
            }

            ctx.strokeStyle = rgba(Theme.accent, 0.55)
            ctx.lineWidth = 1.5
            ctx.beginPath(); ctx.moveTo(plot.px(0), plot.py(0)); ctx.lineTo(plot.px(c[0]), plot.py(c[1])); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(plot.px(1), plot.py(1)); ctx.lineTo(plot.px(c[2]), plot.py(c[3])); ctx.stroke()

            ctx.strokeStyle = rgba(Theme.bright, 0.95)
            ctx.lineWidth = 2.5
            ctx.lineCap = "round"
            ctx.beginPath()
            ctx.moveTo(plot.px(0), plot.py(0))
            ctx.bezierCurveTo(plot.px(c[0]), plot.py(c[1]), plot.px(c[2]), plot.py(c[3]), plot.px(1), plot.py(1))
            ctx.stroke()

            ctx.fillStyle = rgba(fg, 0.8)
            for (const pt of [[0, 0], [1, 1]]) {
                ctx.beginPath(); ctx.arc(plot.px(pt[0]), plot.py(pt[1]), 3, 0, Math.PI * 2); ctx.fill()
            }
        }
    }

    Rectangle {
        visible: plot.playing
        width: 10
        height: 10
        radius: 5 * Theme.round
        x: plot.px(plot.t) - 5
        y: plot.py(plot.p) - 5
        color: Theme.bright
        border.width: 2
        border.color: Theme.alpha(Theme.accent, 0.9)
    }

    Repeater {
        model: 2

        Rectangle {
            required property int index
            readonly property bool grabbed: area.active === index
            width: grabbed || hover.hovered ? 18 : 14
            height: width
            radius: Theme.round * width / 2
            x: plot.px(plot.curve[index * 2]) - width / 2
            y: plot.py(plot.curve[index * 2 + 1]) - height / 2
            color: grabbed ? Theme.bright : Theme.accent
            border.width: 2
            border.color: Theme.alpha(Theme.bg, 0.6)
            Behavior on width { NumberAnimation { duration: Theme.ms(120); easing.type: Easing.OutCubic } }
            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        preventStealing: true
        hoverEnabled: true
        property int active: -1
        property real offX: 0
        property real offY: 0
        cursorShape: active >= 0 ? Qt.ClosedHandCursor : Qt.ArrowCursor

        function nearest(mx, my) {
            const d = i => Math.hypot(plot.px(plot.curve[i * 2]) - mx, plot.py(plot.curve[i * 2 + 1]) - my)
            return d(0) <= d(1) ? 0 : 1
        }

        function drag(mx, my) {
            const c = plot.curve.slice()
            c[active * 2] = Math.round(plot.fromX(mx + offX) * 100) / 100
            c[active * 2 + 1] = Math.round(plot.fromY(my + offY) * 100) / 100
            plot.edited(c)
        }

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) { plot.resetRequested(); return }
            active = nearest(mouse.x, mouse.y)
            const hx = plot.px(plot.curve[active * 2])
            const hy = plot.py(plot.curve[active * 2 + 1])
            if (Math.hypot(hx - mouse.x, hy - mouse.y) <= 30) {
                offX = hx - mouse.x
                offY = hy - mouse.y
            } else {
                offX = 0
                offY = 0
                drag(mouse.x, mouse.y)
            }
        }
        onPositionChanged: mouse => { if (active >= 0) drag(mouse.x, mouse.y) }
        onReleased: active = -1
        onCanceled: active = -1
    }
}
