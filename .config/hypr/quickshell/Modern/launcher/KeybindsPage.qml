import QtQuick
import Quickshell
import Quickshell.Io
import "../../shared"
import "Binds.js" as Binds
import "../common"

Item {
    id: page

    property var counts: ({})
    property real intro: 1
    property string query: ""

    WatchedShared {
        id: source
        path: Quickshell.shellPath("../Modern/base/shortcuts.lua")
    }
    WatchedShared {
        id: common
        path: HyprShared.dir + "/binds.lua"
    }

    readonly property var parsed: Binds.parse(common.text() + "\n" + source.text())
    readonly property var cats: parsed
        .map((c, i) => ({ c: c, i: i, n: counts[c.id] || 0 }))
        .sort((a, b) => b.n - a.n || a.i - b.i)
        .map(x => x.c)

    readonly property var matches: {
        const q = query.trim().toLowerCase()
        if (q === "") return null
        const out = []
        for (const c of parsed)
            for (const b of c.binds)
                if (b.desc.toLowerCase().includes(q) || b.keys.join(" ").toLowerCase().includes(q) || c.label.toLowerCase().startsWith(q))
                    out.push({ keys: b.keys, desc: b.desc, icon: c.icon })
        return out
    }
    onMatchesChanged: {
        list.contentY = 0
        if (matches) searchFade.restart()
    }

    property int current: 0
    property bool touched: false
    readonly property var cur: cats.length > 0 ? cats[Math.min(current, cats.length - 1)] : null
    readonly property string currentId: cur ? cur.id : ""

    property var shown: null
    property int dir: 1
    onCurChanged: {
        if (!shown || !cur || shown.id === cur.id) { shown = cur; return }
        swapAnim.restart()
    }

    function reset() {
        current = 0
        touched = false
        shown = cur
        list.contentY = 0
    }

    function step(d) {
        if (cats.length === 0) return
        dir = d
        touched = true
        current = ring.mod(current + d)
    }

    function pick(i) {
        if (i === current) return
        dir = i > current ? 1 : -1
        touched = true
        current = i
    }

    function handleKey(event) {
        const k = event.key
        if (k === Qt.Key_Right && !matches) step(1)
        else if (k === Qt.Key_Left && !matches) step(-1)
        else if (k === Qt.Key_Down) list.scrollBy(list.rowH * 2)
        else if (k === Qt.Key_Up) list.scrollBy(-list.rowH * 2)
        else return false
        return true
    }

    Radial {
        id: ring
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        width: Math.min(parent.width * 0.62, parent.height * 0.44)
        height: width
        btn: Math.round(width * 0.2)
        entries: page.cats
        current: page.current
        intro: page.intro
        opacity: page.matches ? 0.35 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.ms(240); easing.type: Easing.OutCubic } }
        onPicked: i => page.pick(i)
        onActivated: i => page.pick(i)

        Column {
            anchors.centerIn: parent
            width: parent.width
            spacing: 2

            LabelShared {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: page.matches ? "Search" : page.cur ? page.cur.label : ""
                font.pixelSize: 13
                color: Theme.bright
            }
            LabelShared {
                anchors.horizontalCenter: parent.horizontalCenter
                readonly property int count: page.matches ? page.matches.length : page.cur ? page.cur.binds.length : 0
                text: page.matches ? count + (count === 1 ? " match" : " matches") : page.cur ? count + (count === 1 ? " bind" : " binds") : ""
                font.pixelSize: 10
                color: Theme.dim
            }
        }
    }

    Flickable {
        id: list
        anchors.top: ring.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        width: parent.width
        contentHeight: rows.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        readonly property real rowH: 32

        function scrollBy(d) {
            scroll.stop()
            scroll.from = contentY
            scroll.to = Math.max(0, Math.min(contentHeight - height, (scroll.running ? scroll.to : contentY) + d))
            scroll.start()
        }
        NumberAnimation { id: scroll; target: list; property: "contentY"; duration: Theme.ms(180); easing.type: Easing.OutCubic }

        property real shift: 0
        NumberAnimation { id: searchFade; target: rows; property: "opacity"; from: 0.35; to: 1; duration: Theme.ms(200); easing.type: Easing.OutCubic }

        SequentialAnimation {
            id: swapAnim
            ParallelAnimation {
                NumberAnimation { target: rows; property: "opacity"; to: 0; duration: Theme.ms(90); easing.type: Easing.InQuad }
                NumberAnimation { target: list; property: "shift"; to: -16 * page.dir; duration: Theme.ms(90); easing.type: Easing.InQuad }
            }
            ScriptAction { script: { page.shown = page.cur; list.contentY = 0; list.shift = 16 * page.dir } }
            ParallelAnimation {
                NumberAnimation { target: rows; property: "opacity"; to: 1; duration: Theme.ms(220); easing.type: Easing.OutCubic }
                SettleShared { target: list; property: "shift"; to: 0; duration: Theme.move }
            }
        }

        Column {
            id: rows
            width: list.width
            transform: Translate { x: list.shift }

            Repeater {
                model: page.matches ?? (page.shown ? page.shown.binds : [])

                Item {
                    id: row
                    required property var modelData
                    required property int index
                    width: rows.width
                    height: list.rowH

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 2
                        anchors.bottomMargin: 2
                        radius: Theme.r(8)
                        color: Theme.alpha(Theme.fg, row.index % 2 === 0 ? 0.045 : 0)
                    }

                    Row {
                        id: chips
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        LabelShared {
                            visible: !!row.modelData.icon
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            text: row.modelData.icon || ""
                            font.pixelSize: 11
                            color: Theme.dim
                        }

                        Repeater {
                            model: row.modelData.keys

                            Rectangle {
                                required property string modelData
                                width: label.implicitWidth + 12
                                height: 20
                                radius: Theme.r(6)
                                color: Theme.alpha(Theme.accent, 0.16)
                                border.width: 1
                                border.color: Theme.alpha(Theme.accent, 0.3)

                                LabelShared {
                                    id: label
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    font.pixelSize: 11
                                    color: Theme.bright
                                }
                            }
                        }
                    }

                    LabelShared {
                        anchors.left: chips.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                        text: row.modelData.desc
                        font.pixelSize: 12
                        color: Theme.fg
                    }
                }
            }
        }
    }

    LabelShared {
        anchors.centerIn: list
        visible: page.cats.length === 0 || (page.matches !== null && page.matches.length === 0)
        text: page.cats.length === 0 ? "No binds found in shortcuts.lua" : "No binds match \u201c" + page.query + "\u201d"
        font.pixelSize: 12
        color: Theme.dim
    }
}
