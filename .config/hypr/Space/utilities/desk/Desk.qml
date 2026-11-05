import QtQuick
import "../common"

Item {
    id: desk

    required property var model
    property bool editing: false
    readonly property int grid: 24
    opacity: model.shown

    property real guideX: -1
    property real guideY: -1
    function align(pos, size, lines) {
        let best = null
        for (const at of [0, size / 2, size])
            for (const l of lines)
                if (Math.abs(pos + at - l) <= 10 && (!best || Math.abs(pos + at - l) < Math.abs(best.d))) best = { d: l - pos - at, l: l }
        return best ? [pos + best.d, best.l] : [Math.round(pos / grid) * grid, -1]
    }
    function snap(i, px, py, w, h) {
        const xs = [0, width / 2, width], ys = [0, height / 2, height]
        for (let j = 0; j < widgets.count; j++) {
            const o = widgets.itemAt(j)
            if (j === i || !o || !o.visible) continue
            xs.push(o.x, o.x + o.width / 2, o.x + o.width)
            ys.push(o.y, o.y + o.height / 2, o.y + o.height)
        }
        const [x, gx] = align(px, w, xs), [y, gy] = align(py, h, ys)
        guideX = gx
        guideY = gy
        return [Math.max(0, Math.min(width - w, x)), Math.max(0, Math.min(height - h, y))]
    }

    Repeater {
        model: desk.editing ? Math.ceil(desk.width / desk.grid) : 0
        Rectangle { required property int index; x: index * desk.grid; width: 1; height: desk.height; color: Theme.alpha(Theme.fg, 0.05) }
    }
    Repeater {
        model: desk.editing ? Math.ceil(desk.height / desk.grid) : 0
        Rectangle { required property int index; y: index * desk.grid; height: 1; width: desk.width; color: Theme.alpha(Theme.fg, 0.05) }
    }
    MouseArea { anchors.fill: parent; enabled: desk.editing; onClicked: desk.model.picked = -1 }

    Repeater {
        id: widgets
        model: desk.model.items
        Widget {
            id: wdg
            required property var modelData
            required property int index
            readonly property bool on: desk.editing && desk.model.picked === index
            d: modelData
            editing: desk.editing
            x: modelData.x * desk.width
            y: modelData.y * desk.height
            onNoteEdited: t => desk.model.quiet(index, { text: t })

            Rectangle {
                visible: desk.editing
                anchors.fill: parent
                anchors.margins: -6
                color: "transparent"
                border.width: 1
                border.color: wdg.on ? Theme.accent : Theme.faint
            }
            MouseArea { anchors.fill: parent; enabled: desk.editing; onPressed: m => { desk.model.picked = wdg.index; m.accepted = false } }
            Hud {
                visible: desk.editing
                x: parent.width + 2
                y: -18
                text: "×"
                font.pixelSize: 16
                color: rm.containsMouse ? Theme.warn : Theme.dim
                MouseArea { id: rm; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; onClicked: desk.model.remove(wdg.index) }
            }
            DragHandler {
                enabled: desk.editing
                target: null
                property point from
                onActiveChanged: {
                    if (active) return from = Qt.point(wdg.x, wdg.y)
                    desk.guideX = desk.guideY = -1
                    desk.model.change(wdg.index, { x: wdg.x / desk.width, y: wdg.y / desk.height })
                }
                onTranslationChanged: {
                    if (!active) return
                    const p = desk.snap(wdg.index, from.x + translation.x, from.y + translation.y, wdg.width, wdg.height)
                    wdg.x = p[0]
                    wdg.y = p[1]
                }
            }
            Rectangle {
                visible: wdg.on
                x: parent.width
                y: parent.height
                width: 10
                height: 10
                color: Theme.accent
                DragHandler {
                    target: null
                    property real from: 1
                    property real w0: 80
                    onActiveChanged: {
                        if (active) { from = wdg.s; w0 = Math.max(80, wdg.width); return }
                        if (wdg.live) desk.model.change(wdg.index, { s: wdg.live })
                    }
                    onTranslationChanged: if (active) wdg.live = Math.max(0.5, Math.min(3, from * (1 + translation.x / w0)))
                }
            }
        }
    }

    Rectangle { visible: desk.guideX >= 0; x: desk.guideX; width: 1; height: desk.height; color: Theme.accent }
    Rectangle { visible: desk.guideY >= 0; y: desk.guideY; height: 1; width: desk.width; color: Theme.accent }
}
