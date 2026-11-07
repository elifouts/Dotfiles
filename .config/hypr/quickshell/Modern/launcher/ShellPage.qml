import QtQuick
import Quickshell.Io
import "../../shared"
import "../common"

Item {
    id: page

    property var commands: []
    property var counts: ({})
    property string query: ""
    property bool live: false
    property bool dirty: true
    signal run(string cmd, string key, bool background)

    readonly property var current: wheel.n > 0 ? wheel.entries[wheel.cur] : null

    readonly property var kindRank: ({ alias: 0, "function": 1, bin: 2 })
    readonly property var ordered: {
        const list = commands.map(e => ({ n: e.n, k: e.k, d: e.d, l: e.n.toLowerCase(), dl: (e.d || "").toLowerCase(), sym: /^[a-z0-9]/i.test(e.n) ? 0 : 1 }))
        list.sort((a, b) => kindRank[a.k] - kindRank[b.k] || a.sym - b.sym || (a.l < b.l ? -1 : a.l > b.l ? 1 : 0))
        list.forEach((e, i) => e.order = i)
        return list
    }

    function changed() {
        if (live) refresh()
        else dirty = true
    }
    onQueryChanged: changed()
    onOrderedChanged: changed()
    onLiveChanged: if (live && dirty) refresh()

    function score(e, q) {
        if (e.l === q) return 100
        if (e.l.startsWith(q)) return 90
        if (q.length > 1 && e.l.includes(q)) return 60
        if (q.length > 2 && e.k === "alias" && e.dl.includes(q)) return 30
        return 0
    }

    function refresh() {
        dirty = false
        const q = query.trim()
        const word = q.toLowerCase().split(/\s+/)[0]
        let list
        if (q === "") {
            const used = ordered.filter(e => counts[e.n])
            used.sort((a, b) => counts[b.n] - counts[a.n] || a.order - b.order)
            list = used.concat(ordered.filter(e => !counts[e.n]))
        } else {
            const hits = []
            for (const e of ordered) {
                const s = score(e, word)
                if (s > 0) hits.push({ e: e, s: s, u: counts[e.n] || 0 })
            }
            hits.sort((a, b) => b.s - a.s || b.u - a.u || a.e.n.length - b.e.n.length || a.e.order - b.e.order)
            list = hits.map(h => h.e)
        }
        if (q !== "") {
            const typed = { n: q, k: "run", d: "run as typed" }
            const exact = list.length > 0 && list[0].n.toLowerCase() === word
            if (/\s/.test(q)) list.unshift(typed)
            else if (!exact) list.push(typed)
        }
        wheel.entries = list
        wheel.reset()
    }

    function activate(background) {
        const e = current
        if (!e) return
        page.run(e.n, e.n.split(/\s+/)[0], background)
    }

    function handleKey(event) {
        const k = event.key
        if (k === Qt.Key_Down) wheel.step(1)
        else if (k === Qt.Key_Up) wheel.step(-1)
        else if (k === Qt.Key_PageDown) wheel.step(5)
        else if (k === Qt.Key_PageUp) wheel.step(-5)
        else if (k === Qt.Key_Return || k === Qt.Key_Enter) activate(!!(event.modifiers & Qt.ShiftModifier))
        else return false
        return true
    }

    property string summary: ""
    onCurrentChanged: {
        summary = ""
        if (current && current.k === "bin") lookup.restart()
    }
    Timer {
        id: lookup
        interval: 160
        onTriggered: {
            whatis.running = false
            whatis.command = ["whatis", "-l", "--", page.current ? page.current.n : ""]
            whatis.running = true
        }
    }
    Process {
        id: whatis
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.split("\n")[0].match(/\s-\s(.+)$/)
                page.summary = m ? m[1] : ""
            }
        }
    }

    VWheel {
        id: wheel
        animate: page.live
        anchors.top: parent.top
        anchors.bottom: footer.top
        anchors.bottomMargin: 8
        width: parent.width
        onActivated: page.activate(false)
    }

    Column {
        id: footer
        anchors.bottom: parent.bottom
        width: parent.width
        spacing: 4

        LabelShared {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: !page.current ? (page.commands.length === 0 ? "Loading commands..." : "Nothing matches '" + page.query + "'")
                : page.current.k === "alias" ? "alias  ·  " + page.current.d
                : page.current.k === "function" ? "function from .bashrc"
                : page.current.k === "run" ? "runs the line as typed"
                : (page.summary !== "" ? page.summary : page.current.d)
            font.pixelSize: 12
            color: Theme.fg
        }
        LabelShared {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "↵ run in kitty    ⇧↵ run in background"
            font.pixelSize: 10
            font.letterSpacing: 0.8
            color: Theme.dim
        }
    }
}
