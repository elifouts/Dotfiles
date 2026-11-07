import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "../../shared"
import "../common"
import "menus" as Menus

Item {
    id: ex

    property bool active: false
    property int rev: 0
    property var closing: []
    function isClosing(t) { return closing.includes(addr(t)) }

    readonly property string wallpaper: wallFile.text().trim()

    WatchedShared {
        id: wallFile
        path: Quickshell.env("HOME") + "/.cache/wallpaper-picker/current"
    }

    FileView {
        id: pyprFile
        path: Quickshell.env("HOME") + "/.config/pypr/config.toml"
        printErrors: false
    }
    readonly property var scratch: {
        const out = []
        let name = ""
        for (const line of pyprFile.text().split("\n")) {
            let m = line.match(/^\[scratchpads\.(.+)\]/)
            if (m) { name = m[1]; continue }
            m = line.match(/^class\s*=\s*"(.*)"/)
            if (m && name) out.push({ name: name, cls: m[1], re: m[1].startsWith("re:") ? new RegExp(m[1].slice(3).replace("(?i)", ""), "i") : null })
        }
        return out
    }
    function scratchOf(t) {
        const c = t.lastIpcObject ? t.lastIpcObject.class || "" : ""
        return scratch.find(s => s.re ? s.re.test(c) : s.cls === c)
    }
    function scratchpads() {
        rev
        return Hyprland.toplevels.values.filter(t => t.lastIpcObject && scratchOf(t))
    }

    function refresh() {
        Hyprland.refreshToplevels()
        Hyprland.refreshWorkspaces()
        Hyprland.refreshMonitors()
        settle.restart()
    }
    Timer { id: settle; interval: 60; onTriggered: ex.rev++ }

    onActiveChanged: { if (active) refresh(); else closing = [] }

    readonly property var events: ["openwindow", "closewindow", "movewindow", "movewindowv2", "changefloatingmode",
        "windowtitle", "windowtitlev2", "activewindow", "activewindowv2", "fullscreen", "workspace", "workspacev2",
        "createworkspace", "createworkspacev2", "destroyworkspace", "destroyworkspacev2", "moveworkspace", "moveworkspacev2"]
    Connections {
        target: Hyprland
        enabled: ex.active
        function onRawEvent(event) { if (ex.events.includes(event.name)) debounce.restart() }
    }
    Timer { id: debounce; interval: 80; onTriggered: ex.refresh() }
    Timer { running: ex.active; interval: 1500; repeat: true; onTriggered: ex.refresh() }

    function geometry(mon) {
        rev
        if (!mon) return { x: 0, y: 0, w: 1920, h: 1080 }
        const o = mon.lastIpcObject || {}
        const sc = o.scale || mon.scale || 1
        const turned = (o.transform ?? 0) % 2 === 1
        const w = (turned ? (o.height ?? mon.height) : (o.width ?? mon.width)) / sc
        const h = (turned ? (o.width ?? mon.width) : (o.height ?? mon.height)) / sc
        return { x: o.x ?? mon.x, y: o.y ?? mon.y, w: w, h: h }
    }

    function windowsOn(id) {
        rev
        return Hyprland.toplevels.values
            .filter(t => t.workspace && t.workspace.id === id && t.lastIpcObject && t.lastIpcObject.at
                && t.lastIpcObject.mapped !== false && !t.lastIpcObject.hidden && !scratchOf(t))
            .sort((a, b) => (b.lastIpcObject.focusHistoryID ?? 0) - (a.lastIpcObject.focusHistoryID ?? 0))
    }

    function workspacesOn(screenName) {
        rev
        const all = Hyprland.workspaces.values.filter(w => w.id > 0)
        const ids = all.filter(w => w.monitor && w.monitor.name === screenName).map(w => w.id).sort((a, b) => a - b)
        const used = new Set(all.map(w => w.id))
        let next = 1
        while (used.has(next)) next++
        return { ids: ids, next: next }
    }

    function iconFor(cls) {
        const e = DesktopEntries.heuristicLookup(cls || "") || DesktopEntries.heuristicLookup((cls || "").split("-")[0])
        return Quickshell.iconPath(e && e.icon ? e.icon : (cls || "").toLowerCase(), true)
            || Quickshell.iconPath("application-x-executable", true)
    }

    function appName(cls) {
        const e = DesktopEntries.heuristicLookup(cls || "")
        return e && e.name ? e.name : (cls || "Window")
    }

    function addr(t) {
        return t.lastIpcObject && t.lastIpcObject.address ? t.lastIpcObject.address : "0x" + t.address
    }

    function focusWindow(t) {
        HyprShared.dispatch("hl.dsp.focus({ window = \"address:" + addr(t) + "\" })", "focuswindow address:" + addr(t))
    }

    function moveTo(t, ws, mon) {
        const w = typeof ws === "string" ? "\"" + ws + "\"" : ws
        HyprShared.dispatch("hl.dsp.window.move({ workspace = " + w + ", window = \"address:" + addr(t) + "\", follow = false })",
                       "movetoworkspacesilent " + ws + ",address:" + addr(t))
        if (mon && typeof ws === "number")
            HyprShared.dispatch("hl.dsp.workspace.move({ workspace = " + ws + ", monitor = \"" + mon + "\" })",
                           "moveworkspacetomonitor " + ws + " " + mon)
        debounce.restart()
    }

    function keepCursor(lua, classic) {
        const back = HyprShared.lua ? "hl.dsp.cursor.move({ x = $x, y = $y })" : "movecursor $x $y"
        Quickshell.execDetached(["sh", "-c", 'p=$(hyprctl cursorpos); x=${p%%,*}; y=${p##* }; hyprctl dispatch "$1" >/dev/null; hyprctl dispatch "' + back + '" >/dev/null',
                                 "sh", HyprShared.lua ? lua : classic])
        debounce.restart()
    }

    function swap(a, b) {
        keepCursor("hl.dsp.window.swap({ window = \"address:" + addr(a) + "\", target = \"address:" + addr(b) + "\" })",
                   "swapwindow address:" + addr(b))
    }

    function place(t, x, y) {
        keepCursor("hl.dsp.window.move({ x = " + Math.round(x) + ", y = " + Math.round(y) + ", window = \"address:" + addr(t) + "\" })",
                   "movewindowpixel exact " + Math.round(x) + " " + Math.round(y) + ",address:" + addr(t))
    }

    function closeWindow(t) {
        const kill = /kitty/i.test(t.lastIpcObject ? t.lastIpcObject.class : "")
        closing = closing.concat(addr(t))
        HyprShared.dispatch("hl.dsp.window." + (kill ? "kill" : "close") + "({ window = \"address:" + addr(t) + "\" })",
                       (kill ? "killwindow" : "closewindow") + " address:" + addr(t))
    }

    function clear(id, ids, activeId) {
        windowsOn(id).forEach(w => closeWindow(w))
        const other = ids.find(i => i !== id)
        if (id === activeId && other !== undefined) goTo(other)
    }

    function goTo(id) {
        HyprShared.dispatch("hl.dsp.focus({ workspace = " + id + " })", "workspace " + id)
    }

    function keyOf(windows) { return windows.map(w => w.cmd).sort().join("\n") }
    readonly property var saved: {
        try {
            return JSON.parse(savedFile.text()).map(e => Object.assign(e, { key: keyOf(e.windows) }))
                .sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: "base" }))
        } catch (e) { return [] }
    }
    readonly property var byKey: { const m = {}; for (const e of saved) m[e.key] = e; return m }
    WatchedShared {
        id: savedFile
        path: decodeURIComponent(Qt.resolvedUrl("../overview/workspaces.json").toString().replace(/^file:\/\//, ""))
    }
    function write(list) { savedFile.setText(JSON.stringify(list, (k, v) => k === "key" ? undefined : v, 2)) }
    function forget(e) { write(saved.filter(s => s.key !== e.key)) }
    function rename(e, name) {
        name = name.trim()
        if (name && name !== e.name) write(saved.map(s => s.key === e.key ? Object.assign({}, s, { name: name, renamed: true }) : s))
    }

    function save(id, geom) {
        const wins = windowsOn(id)
        if (!wins.length) return
        cmdlines.wins = wins
        cmdlines.geom = geom
        cmdlines.command = [Quickshell.shellDir + "/style/bar/procs.sh"].concat(wins.map(w => String(w.lastIpcObject.pid)))
        tabs.urls = []
        if (!wins.some(isBrowser)) return cmdlines.running = true
        tabs.command = [Quickshell.shellDir + "/style/bar/tabs.py"].concat(wins.map(w => isBrowser(w) ? w.lastIpcObject.title || " " : ""))
        tabs.running = true
    }

    function isBrowser(t) { return /firefox|librewolf/i.test(t.lastIpcObject.class || "") }

    Process {
        id: tabs
        property var urls: []
        stdout: StdioCollector {
            onStreamFinished: {
                tabs.urls = text.split("\n").map(l => l.split("\x1f").filter(u => u))
                cmdlines.running = true
            }
        }
    }

    function savedTarget(activeId, next) {
        return activeId > 0 && windowsOn(activeId).length === 0 ? activeId : next
    }
    Process {
        id: cmdlines
        property var wins: []
        property var geom: null
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                const q = a => "'" + a.replace(/'/g, "'\\''") + "'"
                const home = Quickshell.env("HOME")
                const qh = a => a === home ? '"$HOME"' : a.startsWith(home + "/") ? '"$HOME"' + q(a.slice(home.length)) : q(a)
                const g = cmdlines.geom
                const base = a => (a || "").split("/").pop()
                const windows = cmdlines.wins.map((w, i) => {
                    const o = w.lastIpcObject
                    const [all, dir, run] = (lines[i] || "").split("\x1e").map(f => (f || "").split("\x1f").filter(a => a))
                    const cut = dir.length ? all.findIndex((a, j) => j > 0 && (a === "-e" || (base(a) === "sh" && all[j + 1] === "-c"))) : -1
                    const c = cut > 0 ? all.slice(0, cut) : all
                    let cmd = c.map(qh).join(" "), app = ex.appName(o.class)
                    const urls = tabs.urls[i] || []
                    if (c.length && urls.length)
                        cmd = q(c[0]) + " --new-window " + q(urls[0]) + urls.slice(1).map(u => " --new-tab " + q(u)).join("")
                    else if (dir.length) {
                        const inner = "cd " + qh(dir[0]) + (run.length ? " && " + run.map(qh).join(" ") : "") + "; exec \"$SHELL\""
                        cmd += (base(c[0]) === "kitty" ? "" : " -e") + " sh -c " + q(inner)
                        if (run.length) app = base(run[/^(perl|python3?|node|bash|sh)$/.test(base(run[0])) && run.length > 1 ? 1 : 0])
                    }
                    return { cmd: cmd, app: app, floating: o.floating, x: o.at[0] - g.x, y: o.at[1] - g.y, w: o.size[0], h: o.size[1] }
                }).filter(w => w.cmd)
                const key = ex.keyOf(windows)
                const old = ex.saved.find(e => e.key === key)
                const name = old && old.renamed ? old.name : [...new Set(windows.map(w => w.app))].join(" · ")
                if (windows.length) ex.write(ex.saved.filter(e => e !== old)
                    .concat([{ name: name, renamed: !!(old && old.renamed), w: g.w, h: g.h, windows: windows }]))
            }
        }
    }

    function fit(e, gw, gh) {
        const sw = Math.max(e.w || 0, ...e.windows.map(w => w.x + w.w)), sh = Math.max(e.h || 0, ...e.windows.map(w => w.y + w.h))
        const s = Math.min(1, gw / sw, gh / sh)
        return { s: s, ox: (gw - sw * s) / 2, oy: (gh - sh * s) / 2 }
    }

    function restore(e, ws, geom) {
        const f = fit(e, geom.w, geom.h)
        launches.ws = ws
        launches.queue = e.windows.slice().sort((a, b) => a.floating - b.floating || a.x - b.x || a.y - b.y)
            .map(w => Object.assign({}, w, { x: Math.round(f.ox + w.x * f.s), y: Math.round(f.oy + w.y * f.s),
                w: Math.round(w.w * f.s), h: Math.round(w.h * f.s) }))
        launches.restart()
        if (typeof ws === "number") goTo(ws)
    }
    Timer {
        id: launches
        property var ws: 0
        property var queue: []
        interval: 350
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const w = queue.shift()
            if (!w) return stop()
            const f = w.floating ? ", float = true, move = \"" + w.x + " " + w.y + "\", size = \"" + w.w + " " + w.h + "\"" : ""
            HyprShared.dispatch("hl.dsp.exec_cmd([==[" + w.cmd + "]==], { workspace = \"" + ws + " silent\"" + f + " })",
                           "exec [workspace " + ws + " silent" + (w.floating ? "; float; move " + w.x + " " + w.y + "; size " + w.w + " " + w.h : "") + "] " + w.cmd)
        }
    }

    component Dots: Row {
        id: dots

        readonly property int activeId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
        readonly property var existing: HyprShared.workspaces
        readonly property var ids: HyprShared.workspaceIds

        function occupied(id) {
            const w = existing.find(w => w.id === id)
            return !!w && (!w.toplevels || w.toplevels.values.length > 0)
        }

        function go(id) {
            if (id !== activeId) HyprShared.dispatch("hl.dsp.focus({ workspace = " + id + " })", "workspace " + id)
        }

        spacing: 6

        Repeater {
            model: dots.ids

            Rectangle {
                required property int modelData
                readonly property bool active: modelData === dots.activeId
                readonly property bool full: dots.occupied(modelData)

                anchors.verticalCenter: parent.verticalCenter
                width: active ? 22 : 8
                height: 8
                radius: 4
                color: active ? Theme.accent
                    : full ? (dotArea.containsMouse ? Theme.bright : Theme.fg)
                    : Theme.alpha(Theme.fg, dotArea.containsMouse ? 0.5 : 0.25)
                Behavior on width { SettleShared { duration: Theme.move } }
                Behavior on color { ColorAnimation { duration: Theme.fast } }

                HoverShared {
                    id: dotArea
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: dots.go(parent.modelData)
                }
            }
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: e => {
                const i = dots.ids.indexOf(dots.activeId)
                const step = e.angleDelta.y > 0 ? -1 : 1
                dots.go(dots.ids[Math.max(0, Math.min(dots.ids.length - 1, (i < 0 ? 0 : i) + step))])
            }
        }
    }

    component SpaceTile: Item {
        id: tile

        property var expose
        property int wsId: 1
        property var monitor: null
        property bool current: false
        property bool isNew: false
        property bool big: false
        property string hint: "New workspace"
        property var target: wsId
        property Item ghost: null
        property bool takesSaved: false
        signal windowPicked(var toplevel)
        signal savedDropped(var entry)
        signal workspacePicked(int id)

        readonly property var geom: expose.geometry(monitor)
        readonly property real k: width / geom.w
        readonly property var windows: isNew ? [] : expose.windowsOn(wsId)
        readonly property real r: Math.min(Theme.rounding, big ? 14 : 8)

        implicitHeight: width * geom.h / geom.w

        ClippingRectangle {
            id: screen
            anchors.fill: parent
            radius: tile.r
            color: Theme.alpha(Theme.fg, 0.06)
            scale: drop.containsDrag ? 1.03 : area.containsMouse && !tile.big ? 1.03 : 1
            Behavior on scale { SettleShared { duration: Theme.fast } }

            Image {
                anchors.fill: parent
                visible: !tile.isNew && tile.expose.wallpaper !== ""
                source: tile.expose.wallpaper !== "" ? "file://" + tile.expose.wallpaper : ""
                sourceSize: Qt.size(Math.ceil(tile.width * 2) || 1, Math.ceil(tile.height * 2) || 1)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: area.containsMouse ? 0.9 : 0.7
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
            }

            HoverShared {
                id: area
                anchors.fill: parent
                onClicked: tile.workspacePicked(tile.wsId)
            }

            Column {
                anchors.centerIn: parent
                visible: tile.isNew
                spacing: 4
                LabelShared {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: ""
                    font.pixelSize: tile.big ? 28 : 16
                    color: area.containsMouse ? Theme.accent : Theme.dim
                }
                LabelShared {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: tile.big
                    text: tile.hint
                    font.pixelSize: 12
                    color: Theme.dim
                }
            }

            Repeater {
                model: ScriptModel { values: tile.windows }

                Item {
                    id: win
                    required property var modelData
                    readonly property var o: modelData.lastIpcObject
                    readonly property bool hot: hover.hovered
                    opacity: tile.ghost && tile.ghost.dragging && tile.ghost.toplevel === modelData ? 0.25 : 1
                    scale: hot && tile.big && !(tile.ghost && tile.ghost.dragging) ? 1.02 : 1
                    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                    Behavior on scale { SettleShared { duration: Theme.fast } }
                    Behavior on x { SettleShared { duration: Theme.move } }
                    Behavior on y { SettleShared { duration: Theme.move } }
                    Behavior on width { SettleShared { duration: Theme.move } }
                    Behavior on height { SettleShared { duration: Theme.move } }
                    x: (o.at[0] - tile.geom.x) * tile.k
                    y: (o.at[1] - tile.geom.y) * tile.k
                    width: Math.max(8, o.size[0] * tile.k)
                    height: Math.max(8, o.size[1] * tile.k)

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: Math.min(tile.r - 2, 6)
                        color: Theme.back(0.85)

                        ScreencopyView {
                            id: shot
                            anchors.fill: parent
                            captureSource: tile.expose.active && !tile.expose.isClosing(win.modelData) ? win.modelData.wayland : null
                            live: tile.expose.active
                            constraintSize: Qt.size(Math.ceil(win.o.size[0] * tile.k * 2), Math.ceil(win.o.size[1] * tile.k * 2))
                        }

                        IconImage {
                            readonly property real full: Math.min(48, Math.min(win.width, win.height) * 0.4)
                            implicitSize: shot.hasContent ? Math.min(full, tile.big ? 22 : 14) : full
                            x: shot.hasContent ? 4 : (win.width - implicitSize) / 2
                            y: shot.hasContent ? win.height - implicitSize - 4 : (win.height - implicitSize) / 2
                            visible: implicitSize >= 8
                            source: tile.expose.iconFor(win.o.class)
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.min(tile.r - 2, 6)
                        color: "transparent"
                        border.width: win.hot ? 2 : 1
                        border.color: win.hot ? Theme.accent : Theme.alpha(Theme.fg, 0.12)
                        Behavior on border.color { ColorAnimation { duration: Theme.fast } }
                    }

                    Rectangle {
                        visible: tile.big || win.hot
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: tile.big ? 8 : 3
                        width: Math.min(label.implicitWidth + 16, Math.max(40, win.width - 8))
                        height: tile.big ? 24 : 16
                        radius: Math.min(Theme.rounding, height / 2)
                        color: Theme.back(0.85)
                        LabelShared {
                            id: label
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, parent.width - 12)
                            text: win.o.title || tile.expose.appName(win.o.class)
                            elide: Text.ElideRight
                            font.pixelSize: tile.big ? 11 : 9
                            color: Theme.bright
                        }
                    }

                    HoverHandler { id: hover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        drag.target: tile.ghost
                        drag.threshold: 6
                        onPressed: mouse => { if (tile.ghost) tile.ghost.start(win, win.modelData, null, mouse.x, mouse.y) }
                        drag.onActiveChanged: if (tile.ghost) drag.active ? tile.ghost.dragging = true : tile.ghost.end()
                        onClicked: tile.windowPicked(win.modelData)
                    }

                    IconButtonShared {
                        visible: win.hot && win.width >= 24
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: tile.big ? 6 : 3
                        text: "\uf00d"
                        font.pixelSize: tile.big ? 13 : 9
                        hot: Theme.warn
                        idle: Theme.bright
                        onClicked: tile.expose.closeWindow(win.modelData)
                    }
                }
            }
        }

        DropArea {
            id: drop
            anchors.fill: parent
            keys: tile.takesSaved ? ["window", "saved"] : ["window"]
            onDropped: d => {
                if (d.source.entry) return tile.savedDropped(d.source.entry)
                const t = d.source.toplevel, o = t.lastIpcObject
                if (tile.isNew || !t.workspace || t.workspace.id !== tile.wsId)
                    return tile.expose.moveTo(t, tile.target, tile.isNew && tile.monitor ? tile.monitor.name : "")
                const px = tile.geom.x + d.x / tile.k, py = tile.geom.y + d.y / tile.k
                if (o.floating) return tile.expose.place(t, px - o.size[0] / 2, py - o.size[1] / 2)
                const under = tile.windows.find(w => w !== t && px >= w.lastIpcObject.at[0] && px < w.lastIpcObject.at[0] + w.lastIpcObject.size[0]
                    && py >= w.lastIpcObject.at[1] && py < w.lastIpcObject.at[1] + w.lastIpcObject.size[1])
                if (under) tile.expose.swap(t, under)
            }
        }

        Rectangle {
            anchors.fill: parent
            scale: screen.scale
            radius: tile.r
            color: "transparent"
            border.width: tile.current || drop.containsDrag ? 2 : 1
            border.color: tile.current || drop.containsDrag ? Theme.accent : Theme.alpha(Theme.fg, area.containsMouse ? 0.25 : 0.1)
            Behavior on border.color { ColorAnimation { duration: Theme.fast } }
        }
    }

    component Actions: Row {
        id: acts
        property var expose
        property int wsId
        property var geom
        property var ids: []
        property int activeId
        property int size: 13
        spacing: size + 1

        IconButtonShared {
            text: "\uf0c7"
            font.pixelSize: acts.size
            onClicked: acts.expose.save(acts.wsId, acts.geom)
        }
        IconButtonShared {
            text: "\uf1f8"
            font.pixelSize: acts.size
            hot: Theme.warn
            onClicked: acts.expose.clear(acts.wsId, acts.ids, acts.activeId)
        }
    }

    component Ghost: Item {
        id: proxy
        property var toplevel: null
        property var entry: null
        property real previewW: 150
        property var previewGeom: ({ w: 1920, h: 1080 })
        property var shown: previewGeom
        property var expose: null
        property bool dragging: false
        property real fromX: 0
        property real fromY: 0
        property real fromW: width
        property real fromH: height
        property real grow: dragging ? 1 : 0
        Behavior on grow { SettleShared { duration: Theme.move } }
        readonly property real g: entry ? grow : 1
        visible: opacity > 0
        opacity: dragging ? 0.9 : 0
        scale: dragging ? 1.04 : 0.96
        Behavior on opacity { NumberAnimation { duration: Theme.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: proxy.dragging ? Theme.settle : Theme.leave } }
        Behavior on scale { SettleShared { duration: Theme.move } }
        z: 10
        Drag.active: dragging
        Drag.hotSpot.x: 0
        Drag.hotSpot.y: 0
        Drag.keys: entry ? ["saved"] : ["window"]

        function start(item, t, e, mx, my) {
            toplevel = t
            entry = e ?? null
            if (e) {
                shown = previewGeom
                width = previewW
                height = previewW * shown.h / shown.w
                Drag.hotSpot.x = width / 2
                Drag.hotSpot.y = height / 2
                const q = item.mapToItem(proxy.parent, mx ?? item.width / 2, my ?? item.height / 2)
                x = q.x - width / 2
                y = q.y - height / 2
                const o = item.mapToItem(proxy.parent, 0, 0)
                fromX = o.x - x
                fromY = o.y - y
                fromW = item.width
                fromH = item.height
                return
            }
            const p = item.mapToItem(proxy.parent, 0, 0)
            Drag.hotSpot.x = mx ?? item.width / 2
            Drag.hotSpot.y = my ?? item.height / 2
            x = p.x
            y = p.y
            width = item.width
            height = item.height
            fromX = 0
            fromY = 0
            fromW = width
            fromH = height
        }
        function end() {
            if (dragging) Drag.drop()
            dragging = false
        }

        Item {
            id: body
            x: proxy.fromX * (1 - proxy.g)
            y: proxy.fromY * (1 - proxy.g)
            width: proxy.fromW + (proxy.width - proxy.fromW) * proxy.g
            height: proxy.fromH + (proxy.height - proxy.fromH) * proxy.g
            ClippingRectangle {
                anchors.fill: parent
                radius: Math.min(Theme.rounding, 6)
                color: Theme.back(0.85)
                ScreencopyView {
                    anchors.fill: parent
                    visible: !proxy.entry
                    captureSource: proxy.expose && proxy.expose.active && proxy.toplevel && !proxy.expose.isClosing(proxy.toplevel) ? proxy.toplevel.wayland : null
                    live: proxy.dragging
                }
                Layout {
                    anchors.fill: parent
                    visible: !!proxy.entry
                    opacity: proxy.g
                    windows: proxy.entry ? proxy.entry.windows : []
                    f: proxy.entry && proxy.expose ? proxy.expose.fit(proxy.entry, proxy.shown.w, proxy.shown.h) : ({ s: 1, ox: 0, oy: 0 })
                    k: body.width / proxy.shown.w
                    fill: Theme.alpha(Theme.fg, 0.1)
                    edge: Theme.alpha(Theme.fg, 0.25)
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: Math.min(Theme.rounding, 6)
                color: "transparent"
                border.width: 1
                border.color: Theme.alpha(Theme.fg, 0.25)
            }
        }
    }

    component Layout: Item {
        id: lay
        property var windows: []
        property var f: ({ s: 1, ox: 0, oy: 0 })
        property real k: 1
        property color fill
        property color edge
        Repeater {
            model: lay.windows
            Rectangle {
                required property var modelData
                x: (lay.f.ox + modelData.x * lay.f.s) * lay.k
                y: (lay.f.oy + modelData.y * lay.f.s) * lay.k
                width: modelData.w * lay.f.s * lay.k
                height: modelData.h * lay.f.s * lay.k
                radius: Math.min(Theme.rounding, 3)
                color: lay.fill
                border.width: 1
                border.color: lay.edge
                LabelShared {
                    anchors.centerIn: parent
                    width: parent.width - 6
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: modelData.app
                    font.pixelSize: 8
                    color: Theme.dim
                }
            }
        }
    }

    component Page: Column {
        id: page

        property var expose
        property var screen
        signal picked()
        signal overview()
        property var renaming: null
        readonly property bool holdOpen: renaming !== null

        readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
        readonly property int activeId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : -1
        readonly property var spaces: expose.workspacesOn(screen ? screen.name : "")
        readonly property var cells: spaces.ids.concat([-1])
        readonly property real gap: 10
        readonly property int cols: Math.max(1, Math.min(3, cells.length, Math.floor((width + gap) / (150 + gap))))
        readonly property int rows: Math.ceil(cells.length / cols)
        readonly property var geom: expose.geometry(monitor)
        readonly property real tileW: Math.min((width - (cols - 1) * gap) / cols, (420 / rows - 18) * geom.w / geom.h)

        spacing: 12

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: grid.width
            height: grid.height
            z: 1

            Grid {
                id: grid
                columns: page.cols
                spacing: page.gap

                Repeater {
                    model: page.cells

                    Column {
                        id: cell
                        required property int modelData
                        readonly property bool isNew: modelData === -1
                        readonly property int wsId: isNew ? page.spaces.next : modelData
                        readonly property int count: page.expose.windowsOn(wsId).length
                        spacing: 5

                        SpaceTile {
                            width: page.tileW
                            expose: page.expose
                            monitor: page.monitor
                            wsId: cell.wsId
                            isNew: cell.isNew
                            ghost: proxy
                            takesSaved: cell.isNew || cell.count === 0
                            current: cell.wsId === page.activeId
                            onWindowPicked: t => { page.picked(); page.expose.focusWindow(t) }
                            onWorkspacePicked: id => { page.picked(); page.expose.goTo(id) }
                            onSavedDropped: e => { page.picked(); page.expose.restore(e, cell.wsId, page.geom) }
                        }
                        Item {
                            width: page.tileW
                            height: 14
                            LabelShared {
                                x: 2
                                text: cell.isNew ? "New" : cell.wsId + "  ·  " + (cell.count === 0 ? "empty" : cell.count + (cell.count > 1 ? " windows" : " window"))
                                font.pixelSize: 10
                                color: cell.wsId === page.activeId ? Theme.accent : Theme.dim
                            }
                            Actions {
                                visible: !cell.isNew && cell.count > 0
                                anchors.right: parent.right
                                anchors.rightMargin: 2
                                size: 10
                                expose: page.expose
                                wsId: cell.wsId
                                geom: page.geom
                                ids: page.spaces.ids
                                activeId: page.activeId
                            }
                        }
                    }
                }
            }

            Ghost { id: proxy; previewW: page.tileW; previewGeom: page.geom; expose: page.expose }
        }

        Menus.Group {
            title: "Saved"
            visible: page.expose.saved.length > 0
            Column {
                width: parent.width
                spacing: 2
                move: Transition { SettleShared { property: "y"; duration: Theme.move } }
            Repeater {
                model: ScriptModel { values: page.expose.saved.map(e => e.key) }
                Menus.Entry {
                    id: savedRow
                    required property string modelData
                    readonly property var entry: page.expose.byKey[modelData] ?? { name: "", windows: [] }
                    glyph: "\uf0c7"
                    label: entry.name
                    sub: entry.windows.length + (entry.windows.length > 1 ? " windows" : " window")
                    Pop { target: savedRow; label: savedRow.label }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true
                        drag.target: proxy
                        drag.threshold: 6
                        onPressed: mouse => proxy.start(savedRow, null, savedRow.entry, mouse.x, mouse.y)
                        drag.onActiveChanged: drag.active ? proxy.dragging = true : proxy.end()
                        onClicked: { page.picked(); page.expose.restore(savedRow.entry, page.expose.savedTarget(page.activeId, page.spaces.next), page.geom) }
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14
                        visible: savedRow.hot || pencil.hovered || bin.hovered
                        LabelShared {
                            text: "\uf040"
                            font.pixelSize: 11
                            color: pencil.hovered ? Theme.accent : Theme.dim
                            HoverHandler { id: pencil }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.renaming = savedRow.modelData
                            }
                        }
                        LabelShared {
                            text: "\uf1f8"
                            font.pixelSize: 11
                            color: bin.hovered ? Theme.warn : Theme.dim
                            HoverHandler { id: bin }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.expose.forget(savedRow.entry)
                            }
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        visible: page.renaming === savedRow.modelData
                        radius: Math.min(Theme.rounding, 8)
                        color: Theme.back(0.95)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.6)
                        onVisibleChanged: if (visible) { field.text = savedRow.entry.name; field.selectAll(); field.forceActiveFocus() }
                        MouseArea { anchors.fill: parent }
                        TextInput {
                            id: field
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 12
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.sans
                            font.pixelSize: 13
                            color: Theme.bright
                            selectionColor: Theme.alpha(Theme.accent, 0.5)
                            clip: true
                            onAccepted: { const e = savedRow.entry, t = text; page.renaming = null; page.expose.rename(e, t) }
                            Keys.onEscapePressed: page.renaming = null
                            onActiveFocusChanged: if (!activeFocus && page.renaming === savedRow.modelData) page.renaming = null
                        }
                    }
                }
            }
            }
        }

        Menus.Group {
            Menus.Entry {
                glyph: "󰕮"
                label: "Overview"
                trailing: "Super + Tab"
                onClicked: { page.picked(); page.overview() }
            }
        }
    }
}
