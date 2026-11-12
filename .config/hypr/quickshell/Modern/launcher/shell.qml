import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../shared"
import "../common"

ShellRoot {
    id: root

    readonly property string helper: HyprShared.util + "/launcher.py"
    readonly property string terminal: "kitty"
    readonly property string cacheDir: HyprShared.home + "/.cache/launcher"
    readonly property string appCache: cacheDir + "/apps"
    readonly property string homeCache: cacheDir + "/commands"
    readonly property string shellCache: cacheDir + "/shell"
    readonly property string bindCache: cacheDir + "/keybinds"

    property alias active: morph.active
    property alias leaving: morph.leaving
    property alias t: morph.t
    property real gridIntro: 1
    property alias targetScreen: morph.screen

    readonly property var tabs: [
        { id: "home", label: "Home", title: "Home", icon: "", search: "" },
        { id: "apps", label: "Apps", title: "Applications", icon: "", search: "Search apps" },
        { id: "commands", label: "Commands", title: "Commands", icon: "", search: "Search commands" },
        { id: "keybinds", label: "Keybinds", title: "Keybinds", icon: "", search: "Search keybinds" }
    ]
    readonly property int homeTab: tabIndex("home")
    property int tab: homeTab
    readonly property string tabId: tabs[tab].id
    function tabIndex(id) { return tabs.findIndex(x => x.id === id) }
    readonly property bool searchable: tabs[tab].search !== ""
    property real introHome: 0
    property real introBinds: 0

    readonly property real u: HyprShared.scaleFor(win.screen)
    readonly property int cols: 4
    readonly property real cell: Math.round(70 * u)
    readonly property real gap: Math.round(26 * u)
    readonly property real hlPad: Math.round(Math.round(14 * u) * 0.6) * 0.6
    readonly property real gridInset: Math.max(hlPad + 4, Math.round(gap * 0.4))
    readonly property real pad: Math.round(18 * u)
    readonly property real cardW: cols * cell + (cols - 1) * gap + gridInset * 2 + pad * 2
    readonly property real cardH: Math.round(Math.min((win.screen ? win.screen.height : 1080) * 0.72, 580 * u))

    readonly property real dot: Math.round(52 * u)


    property var drun: ({ hide: [], paths: {} })
    property var appUses: ({})
    property var apps: []
    property var results: []
    property var slots: ({})
    property int selected: 0
    property bool searchPinned: false
    readonly property string query: ui ? ui.pSearch.text : ""
    readonly property var picked: results.length > 0 ? results[Math.min(selected, results.length - 1)] : null

    Process {
        id: scan
        command: ["python3", root.helper, "apps"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.drun = JSON.parse(text) } catch (e) {}
                rebuild.restart()
            }
        }
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.appsKey = ""; rebuild.restart(); rescan.restart() }
    }
    Timer { id: rebuild; interval: 120; onTriggered: root.buildApps() }
    Timer { id: rescan; interval: 1500; onTriggered: scan.running = true }

    readonly property var music: {
        try { return JSON.parse(musicFile.text()) } catch (e) { return { open: false } }
    }
    WatchedShared {
        id: musicFile
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/music-player.json"
    }

    Process {
        running: true
        command: ["python3", root.helper, "init", root.appCache, root.homeCache, root.shellCache, root.bindCache]
        onExited: {
            appCacheFile.reload()
            homeCacheFile.reload()
            shellCacheFile.reload()
            bindCacheFile.reload()
        }
    }

    WatchedShared {
        id: appCacheFile
        path: root.appCache
        onLoaded: root.appUses = root.counts(text())
    }

    function counts(text) {
        const out = {}
        for (const line of (text || "").split("\n")) {
            const m = line.match(/^(\d+) (.+)$/)
            if (m) out[m[2]] = (out[m[2]] || 0) + parseInt(m[1])
        }
        return out
    }

    function bump(cache, key) {
        if (key) Quickshell.execDetached(["python3", helper, "bump", cache, key])
    }

    property string appsKey: ""
    function buildApps() {
        const hide = new Set(drun.hide || [])
        const paths = drun.paths || {}
        const list = DesktopEntries.applications.values
            .filter(e => !e.noDisplay && !hide.has(e.id) && e.name !== "")
            .sort((a, b) => a.name.localeCompare(b.name))
        const key = list.map(e => e.id + "\u0001" + e.name + "\u0001" + e.icon + "\u0001" + (paths[e.id] || "")).join("\u0002")
        if (key === appsKey) return
        appsKey = key
        apps = list.map((e, i) => ({
            id: e.id,
            entry: e,
            name: e.name,
            icon: e.icon,
            order: i,
            path: (drun.paths || {})[e.id] || "",
            n: e.name.toLowerCase(),
            words: e.name.toLowerCase().split(/[\s\-_.]+/),
            g: (e.genericName || "").toLowerCase(),
            kw: (e.keywords || []).map(k => k.toLowerCase()),
            idl: e.id.toLowerCase(),
            c: (e.comment || "").toLowerCase()
        }))
        refresh()
    }

    function subsequence(s, q) {
        let j = 0
        for (let i = 0; i < s.length && j < q.length; i++) if (s[i] === q[j]) j++
        return j === q.length
    }

    function score(a, q) {
        if (a.n === q) return 100
        if (a.n.startsWith(q)) return 90
        if (a.words.some(w => w.startsWith(q))) return 80
        if (a.n.includes(q)) return 70
        if (a.g.includes(q)) return 55
        if (a.kw.some(k => k.startsWith(q))) return 50
        if (a.idl.includes(q)) return 45
        if (q.length > 2 && a.c.includes(q)) return 30
        if (subsequence(a.n, q)) return 20
        return 0
    }

    function refresh() {
        const q = query.trim().toLowerCase()
        const hits = []
        for (const a of apps) {
            const s = q === "" ? 1 : score(a, q)
            if (s > 0) hits.push({ a: a, s: s, u: appUses[a.path] || 0 })
        }
        hits.sort((x, y) => y.s - x.s || y.u - x.u || x.a.order - y.a.order)
        const map = {}
        hits.forEach((h, i) => map[h.a.id] = i)
        results = hits.map(h => h.a)
        slots = map
        selected = 0
        if (ui) {
            ui.pGrid.mouseMoved = false
            ui.pGrid.scrollTo(0)
        }
    }

    onQueryChanged: refresh()

    function launch(a) {
        if (!a) return
        const e = DesktopEntries.byId(a.id) || a.entry
        if (e.runInTerminal) Quickshell.execDetached([terminal, "-e"].concat(e.command))
        else e.execute()
        bump(appCache, a.path)
        close()
    }

    function moveSelection(d) {
        const n = results.length
        if (n === 0) return
        const s = selected + d
        if (s < 0 || (s > n - 1 && Math.floor(selected / cols) === Math.floor((n - 1) / cols))) return
        selected = Math.max(0, Math.min(n - 1, s))
    }


    WatchedShared {
        id: homeCacheFile
        path: root.homeCache
    }
    WatchedShared {
        id: shellCacheFile
        path: root.shellCache
    }
    WatchedShared {
        id: bindCacheFile
        path: root.bindCache
    }

    property var shellCommands: []
    Process {
        id: scanCommands
        command: ["python3", root.helper, "commands"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.shellCommands = JSON.parse(text) } catch (e) {}
            }
        }
    }

    NumberAnimation { id: introHomeAnim; target: root; property: "introHome"; from: 0; to: 1; duration: Theme.ms(520) }
    NumberAnimation { id: introBindsAnim; target: root; property: "introBinds"; from: 0; to: 1; duration: Theme.ms(520) }
    NumberAnimation { id: gridIntroAnim; target: root; property: "gridIntro"; from: 0; to: 1; duration: Theme.ms(720) }

    function replayIntro() {
        if (tabId === "apps") gridIntroAnim.restart()
        else if (tabId === "home") introHomeAnim.restart()
        else if (tabId === "keybinds") introBindsAnim.restart()
    }

    function runHome(id, cmd, afterClose) {
        bump(homeCache, id)
        close()
        HyprShared.run((afterClose ? "sleep 0.3; " : "") + cmd)
    }

    function runShell(cmd, key, background) {
        bump(shellCache, key)
        close()
        if (background) Quickshell.execDetached(["bash", "-ic", cmd])
        else Quickshell.execDetached([terminal, "--hold", "env", "NOFETCH=1", "bash", "-ic", cmd])
    }


    function setTab(i) {
        i = Math.max(0, Math.min(tabs.length - 1, i))
        if (i !== tab) {
            tab = i
            replayIntro()
        }
        focusTab()
    }

    function focusTab() {
        if (searchable) ui?.pSearch.input.forceActiveFocus()
        else ui?.forceActiveFocus()
    }

    function back() {
        if (tabId === "home" && ui?.pHome.cancel()) return
        if (searchable && (query !== "" || searchPinned)) {
            if (ui) ui.pSearch.text = ""
            searchPinned = false
            return
        }
        close()
    }

    function handleKey(event) {
        const k = event.key
        const ctrl = event.modifiers & Qt.ControlModifier
        if (ui) ui.pGrid.mouseMoved = false

        if (k === Qt.Key_Escape) { back(); return true }
        if (k === Qt.Key_Backtab || (k === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) { setTab((tab + tabs.length - 1) % tabs.length); return true }
        if (k === Qt.Key_Tab) { setTab((tab + 1) % tabs.length); return true }
        if (ctrl && k >= Qt.Key_1 && k <= Qt.Key_4) { setTab(k - Qt.Key_1); return true }

        if (tabId === "apps") {
            if (k === Qt.Key_Right) moveSelection(1)
            else if (k === Qt.Key_Left) moveSelection(-1)
            else if (k === Qt.Key_Down) moveSelection(cols)
            else if (k === Qt.Key_Up) moveSelection(-cols)
            else if (k === Qt.Key_PageDown) moveSelection(cols * 3)
            else if (k === Qt.Key_PageUp) moveSelection(-cols * 3)
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) launch(picked)
            else return false
            return true
        }
        if (tabId === "home") return ui.pHome.handleKey(event)
        if (tabId === "commands") return ui.pShell.handleKey(event)
        return ui.pBinds.handleKey(event)
    }



    Component.onCompleted: {
        scan.running = true
        scanCommands.running = true
    }


    function show(which) {
        const i = tabs.findIndex(x => x.id === which)
        if (active && !leaving) {
            if (i >= 0) setTab(i)
            return
        }
        if (!active) {
            tab = i >= 0 ? i : homeTab
        } else if (i >= 0) {
            tab = i
        }
        morph.show()
    }

    function begin() {
        morph.open()
        Theme.refresh()
        focusTab()
        replayIntro()
    }

    function close() {
        if (!active || leaving) return
        if (tabId === "keybinds" && ui?.pBinds.touched) bump(bindCache, ui.pBinds.currentId)
        morph.close()
    }

    function toggle() {
        if (active && !leaving) close()
        else show("")
    }

    Panel {
        id: morph
        onBegin: root.begin()
        onClosed: {
            root.searchPinned = false
            if (ui) ui.pSearch.text = ""
            root.refresh()
            if (ui) {
                ui.pShell.dirty = true
                ui.pHome.reset()
                ui.pBinds.reset()
            }
            scanCommands.running = true
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle() }
        function open(): void { root.show("") }
        function close(): void { root.close() }
        function tab(id: string): void { root.show(id) }
    }

    readonly property Item ui: ld.item


    PanelWindow {
        id: win
        visible: root.active
        screen: root.targetScreen ?? Quickshell.screens[0]
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Normal
        mask: Region {
            item: root.active && !root.leaving ? ld.item : null
            Region {
                readonly property var m: root.music.open && root.music.screen === win.screen?.name ? root.music : null
                intersection: Intersection.Subtract
                x: m ? (m.x ?? Math.round((win.width - m.side) / 2)) : 0
                y: m ? (m.y ?? m.top) : 0
                width: m ? m.side : 0
                height: m ? m.side : 0
            }
        }
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "app-drawer"
        WlrLayershell.keyboardFocus: root.active && !root.leaving ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Loader {
            id: ld
            anchors.fill: parent
            active: root.active || morph.warm
            sourceComponent: Component {
                Item {
                    property alias pSearch: search
                    property alias pGrid: grid
                    property alias pHome: homePage
                    property alias pShell: shellPage
                    property alias pBinds: binds
                    anchors.fill: parent
                    focus: true

                    Keys.onPressed: event => {
                        if (root.handleKey(event)) { event.accepted = true; return }
                        const ch = event.text
                        if (ch.length === 1 && ch >= " " && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                            root.setTab(root.tabIndex("apps"))
                            search.text += ch
                            event.accepted = true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: root.close()
                    }

                    Item {
                        id: card
                        width: root.dot + (root.cardW - root.dot) * morph.mw
                        height: root.dot + (root.cardH - root.dot) * morph.mh
                        readonly property real rest: Math.min(root.dot / 2, Theme.rounding)
                        readonly property real radius: Math.max(rest, root.dot / 2 - (root.dot / 2 - rest) * Math.min(1, morph.mw))
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        opacity: root.active ? Math.min(1, root.t * 8) : 0
                        transform: Translate { y: (1 - morph.rise) * (root.dot + 24) }

                        MouseArea { anchors.fill: parent }

                        Rectangle {
                            width: parent.width
                            height: parent.height + card.radius + 2
                            radius: card.radius
                            color: Theme.panel
                            border.width: 1
                            border.color: Theme.edge
                        }

                        Item {
                            anchors.fill: parent
                            clip: true

                        Item {
                            id: content
                            width: root.cardW - root.pad * 2
                            height: root.cardH - root.pad - Math.round(root.pad * 0.7)
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: Math.round(root.pad * 0.7)

                            Item {
                                id: header
                                width: parent.width
                                height: Math.round(36 * root.u)
                                opacity: morph.stage(0.55)
                                transform: Translate { y: 10 * (1 - morph.stage(0.5)) }

                                SearchPill {
                                    id: search
                                    height: parent.height
                                    fullWidth: header.width
                                    placeholder: root.tabs[root.tab].search
                                    expanded: root.searchable && (root.searchPinned || root.query !== "")
                                    hint: root.query === "" ? ""
                                        : root.tabId === "apps" ? (root.picked ? root.picked.name : "")
                                        : root.tabId === "commands" && shellPage.current ? shellPage.current.n : ""
                                    onClicked: {
                                        root.searchPinned = true
                                        if (!root.searchable) root.setTab(root.tabIndex("apps"))
                                        else root.focusTab()
                                    }
                                    keyHandler: event => root.handleKey(event)
                                }

                                LabelShared {
                                    id: title
                                    anchors.left: parent.left
                                    anchors.leftMargin: header.height + 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.tabs[root.tab].title
                                    font.pixelSize: 17
                                    color: Theme.bright
                                    property real fade: 1
                                    opacity: fade * (1 - Math.min(1, search.open))
                                    transform: Translate { id: titleShift }

                                    Connections {
                                        target: root
                                        function onTabChanged() { titleAnim.restart() }
                                    }
                                    ParallelAnimation {
                                        id: titleAnim
                                        NumberAnimation { target: titleShift; property: "y"; from: 6; to: 0; duration: Theme.move; easing.type: Easing.OutCubic }
                                        NumberAnimation { target: title; property: "fade"; from: 0; to: 1; duration: Theme.ms(220); easing.type: Easing.OutCubic }
                                    }
                                }

                                LabelShared {
                                    anchors.right: parent.right
                                    anchors.left: title.right
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideRight
                                    text: root.tabId === "apps" ? (root.picked ? root.picked.name : "")
                                        : root.tabId === "home" ? "Enter to run"
                                        : root.tabId === "commands" ? root.shellCommands.length + " commands"
                                        : "shortcuts.lua"
                                    font.pixelSize: 12
                                    color: Theme.dim
                                    opacity: 1 - Math.min(1, search.open)
                                }
                            }

                            Item {
                                anchors.top: header.bottom
                                anchors.topMargin: Math.round(12 * root.u)
                                anchors.bottom: tabBar.top
                                anchors.bottomMargin: Math.round(10 * root.u)
                                width: parent.width
                                opacity: morph.stage(0.62)

                                Page {
                                    tab: "apps"
                                    AppGrid {
                                        id: grid
                                        anchors.fill: parent
                                        apps: root.apps
                                        slots: root.slots
                                        count: root.results.length
                                        selected: root.selected
                                        cols: root.cols
                                        cell: root.cell
                                        gap: root.gap
                                        hlPad: root.hlPad
                                        intro: root.gridIntro
                                        emptyText: root.apps.length === 0 ? "Loading applications..." : "Nothing matches '" + root.query + "'"
                                        onLaunch: app => root.launch(app)
                                        onHover: slot => root.selected = slot
                                    }
                                }

                                Page {
                                    tab: "home"
                                    HomePage {
                                        id: homePage
                                        anchors.fill: parent
                                        counts: root.counts(homeCacheFile.text())
                                        intro: root.introHome
                                        onRun: (id, cmd, after) => root.runHome(id, cmd, after)
                                    }
                                }

                                Page {
                                    tab: "commands"
                                    ShellPage {
                                        id: shellPage
                                        anchors.fill: parent
                                        commands: root.shellCommands
                                        counts: root.counts(shellCacheFile.text())
                                        query: root.query
                                        live: root.active && root.tabId === "commands"
                                        onRun: (cmd, key, background) => root.runShell(cmd, key, background)
                                    }
                                }

                                Page {
                                    tab: "keybinds"
                                    KeybindsPage {
                                        id: binds
                                        anchors.fill: parent
                                        counts: root.counts(bindCacheFile.text())
                                        intro: root.introBinds
                                        query: root.query
                                    }
                                }
                            }

                            Item {
                                id: tabBar
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                readonly property real cellW: Math.round(Math.min(96 * root.u, (content.width - 12) / root.tabs.length))
                                readonly property real gapW: 4
                                width: cellW * root.tabs.length + gapW * (root.tabs.length - 1)
                                height: Math.round(32 * root.u)
                                opacity: morph.stage(0.7)
                                transform: Translate { y: 8 * (1 - morph.stage(0.66)) }

                                Rectangle {
                                    width: tabBar.cellW
                                    height: parent.height
                                    radius: Theme.r(9)
                                    x: root.tab * (tabBar.cellW + tabBar.gapW)
                                    color: Theme.soft(Theme.accent)
                                    Behavior on x { SettleShared { duration: Theme.move } }
                                }

                                Repeater {
                                    model: root.tabs

                                    Item {
                                        id: tabItem
                                        required property var modelData
                                        required property int index
                                        readonly property bool on: root.tab === index
                                        x: index * (tabBar.cellW + tabBar.gapW)
                                        width: tabBar.cellW
                                        height: tabBar.height

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 6

                                            LabelShared {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: tabItem.modelData.icon
                                                font.pixelSize: 13
                                                color: tabItem.on ? Theme.ink : tabArea.containsMouse ? Theme.bright : Theme.dim
                                                Behavior on color { ColorAnimation { duration: Theme.fast } }
                                            }
                                            LabelShared {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: tabItem.modelData.label
                                                font.pixelSize: 11
                                                color: tabItem.on ? Theme.ink : tabArea.containsMouse ? Theme.bright : Theme.dim
                                                Behavior on color { ColorAnimation { duration: Theme.fast } }
                                            }
                                        }

                                        HoverShared {
                                            id: tabArea
                                            anchors.fill: parent
                                            onClicked: root.setTab(tabItem.index)
                                        }
                                    }
                                }
                            }
                        }
                        }
                    }
                }
            }
        }
    }

    component Page: Item {
        required property string tab
        readonly property int index: root.tabIndex(tab)
        readonly property bool on: root.tab === index
        anchors.fill: parent
        enabled: on
        visible: on || opacity > 0.01
        opacity: on ? 1 : 0
        property real slide: on ? 0 : (index < root.tab ? -1 : 1) * 28
        Behavior on opacity { NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutCubic } }
        Behavior on slide { SettleShared { duration: Theme.move } }
        transform: Translate { x: slide }
    }
}
