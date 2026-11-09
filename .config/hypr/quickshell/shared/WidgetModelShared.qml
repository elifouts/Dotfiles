import QtQuick
import Quickshell
import Quickshell.Io
import "../style/common"

Scope {
    id: dm

    required property var screen
    required property string style
    readonly property bool tall: (screen?.height ?? 0) > (screen?.width ?? 1)
    readonly property string file: HyprShared.dir + "/state/layouts/" + style + "/" + role + ".json"
    readonly property string role: {
        const s = screen
        if (!s) return "none"
        const base = m => (m.width >= m.height ? "landscape-" : "portrait-") + m.width + "x" + m.height
        const twins = Quickshell.screens.filter(m => base(m) === base(s)).sort((a, b) => a.x - b.x)
        return base(s) + (twins.length > 1 ? "-" + twins.indexOf(s) : "")
    }

    property var items: []
    property int picked: -1
    property real shown: 1

    readonly property var defaults: ({
        modern: [[{ type: "clock", x: 0.025, y: 0.044, s: 1.99, style: "glow", align: "left" },
                  { type: "stats", x: 0.025, y: 0.244, s: 1, style: "glow", align: "left" }],
                 [{ type: "media", x: 0.294, y: 0.213, s: 1.48, style: "plain", align: "left" },
                  { type: "viz", x: 0.339, y: 0.138, s: 1.71, style: "plain", align: "left" }]],
        space: [[{ type: "clock", x: 0.013, y: 0.067, s: 2.4, style: "glow", align: "left" },
                 { type: "stats", x: 0.013, y: 0.311, s: 1.46, style: "glow", align: "left" }],
                [{ type: "viz", x: 0.29, y: 0.488, s: 2.24, style: "plain", align: "left" },
                 { type: "media", x: 0.272, y: 0.35, s: 1.64, style: "plain", align: "left" }]]
    })
    function fallback() {
        return JSON.parse(JSON.stringify((defaults[style] ?? defaults.modern)[tall ? 1 : 0]))
    }

    FileView {
        id: layout
        path: dm.file
        atomicWrites: true
        printErrors: false
        onLoaded: { try { dm.show(JSON.parse(text())) } catch (e) { dm.show(dm.fallback()) } }
        onLoadFailed: dm.show(dm.fallback())
    }
    property var pending: []
    function show(list) { pending = list; swap.restart() }
    SequentialAnimation {
        id: swap
        SettleShared { target: dm; property: "shown"; to: 0; duration: Theme.quick }
        ScriptAction { script: { dm.items = dm.pending; dm.picked = -1 } }
        SettleShared { target: dm; property: "shown"; to: 1; duration: Theme.quick * 1.5 }
    }

    Timer { id: saveTimer; interval: 300; onTriggered: layout.setText(JSON.stringify(dm.items)) }
    function change(i, patch) {
        const next = items.slice()
        next[i] = Object.assign({}, next[i], patch)
        items = next
        saveTimer.restart()
    }
    function quiet(i, patch) {
        Object.assign(items[i], patch)
        saveTimer.restart()
    }
    function add(type) {
        items = items.concat([{ type: type, x: 0.4, y: 0.4, s: 1, style: "plain", align: "left", text: type === "note" ? "note" : undefined }])
        picked = items.length - 1
        saveTimer.restart()
    }
    function remove(i) {
        items = items.filter((_, j) => j !== i)
        picked = -1
        saveTimer.restart()
    }
}
