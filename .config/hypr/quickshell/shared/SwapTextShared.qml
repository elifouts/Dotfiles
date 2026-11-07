import QtQuick
import "../style/common"

LabelShared {
    id: s

    property string value: ""
    property string shown: ""
    property real typed: 1
    property real shift: 0
    property int dir: 1
    readonly property real fullWidth: metrics.advanceWidth

    text: shown.slice(0, Math.ceil(shown.length * typed))
    transform: Translate { x: s.shift }

    TextMetrics { id: metrics; font: s.font; text: s.value }

    Component.onCompleted: shown = value
    onValueChanged: {
        if (shown === "" || value === "" || !visible) {
            swap.stop()
            shown = value
            typed = 1
            shift = 0
            opacity = 1
            return
        }
        dir = MediaShared.skipDir()
        swap.restart()
    }

    SequentialAnimation {
        id: swap
        ParallelAnimation {
            NumberAnimation { target: s; property: "opacity"; to: 0; duration: Theme.ms(90); easing.type: Easing.InQuad }
            NumberAnimation { target: s; property: "shift"; to: -s.dir * 14; duration: Theme.ms(90); easing.type: Easing.InQuad }
        }
        ScriptAction { script: { s.shown = s.value; s.typed = 0; s.shift = s.dir * 14 } }
        ParallelAnimation {
            NumberAnimation { target: s; property: "opacity"; to: 1; duration: Theme.ms(120) }
            SettleShared { target: s; property: "shift"; to: 0; duration: Theme.ms(260) }
            NumberAnimation { target: s; property: "typed"; to: 1; duration: Theme.ms(Math.min(420, 140 + s.value.length * 12)); easing.type: Easing.OutQuad }
        }
    }
}
