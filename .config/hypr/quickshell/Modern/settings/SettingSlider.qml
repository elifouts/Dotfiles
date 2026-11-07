import QtQuick
import "../../shared"
import "../common"

Item {
    id: control

    property var def
    readonly property var raw: StoreShared.values[def.key]
    readonly property bool ready: raw !== undefined && raw !== null
    readonly property real step: def.step
    readonly property int decimals: {
        const s = String(step)
        const i = s.indexOf(".")
        return i < 0 ? 0 : s.length - i - 1
    }
    readonly property real shown: ready ? raw : def.min
    property bool hot: false

    implicitHeight: 58
    opacity: ready ? 1 : 0.35

    LabelShared {
        x: Theme.pad
        y: 10
        text: control.def.label
        font.pixelSize: 13
        color: control.hot ? Theme.bright : Theme.fg
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    LabelShared {
        anchors.right: parent.right
        anchors.rightMargin: Theme.pad
        y: 10
        text: Number(control.shown).toFixed(control.decimals) + control.def.unit
        font.pixelSize: 13
        color: Theme.accent
    }

    Slider {
        x: Theme.pad
        y: 30
        width: parent.width - Theme.pad * 2
        enabled: control.ready
        scrollable: false
        from: control.def.min
        to: control.def.max
        value: control.shown
        onHotChanged: control.hot = hot
        onMoved: v => {
            v = Number(Math.max(control.def.min, Math.min(control.def.max,
                control.def.min + Math.round((v - control.def.min) / control.step) * control.step)).toFixed(control.decimals))
            if (v !== control.raw) StoreShared.set(control.def.key, v)
        }
    }

    ResetArea { key: control.def.key }
}
