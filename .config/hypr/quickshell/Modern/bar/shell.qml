import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick.Shapes
import "../../shared"
import "../common"
import "island"

ShellRoot {
    id: shell

    WatchedShared {
        id: kindFile
        path: HyprShared.state + "/bar"
    }
    WatchedShared {
        id: ownStyle
        path: Quickshell.shellDir + "/style.json"
    }
    readonly property bool standalone: ownStyle.text().trim() !== ""
    readonly property bool chosen: standalone || kindFile.text().trim() === "quickshell"
    property bool stopped: false
    onChosenChanged: stopped = false

    IpcHandler {
        target: "bar"
        function refresh(): void { kindFile.reload() }
        function toggle(): void { shell.stopped = !shell.stopped }
        function menu(name: string): void { if (bar.item) bar.item.open(name === "wifi" || name === "bluetooth" ? "network" : name, "") }
        function workspaces(): void { menu("workspaces") }
        function island(tab: string): void { if (bar.item) bar.item.open("island", tab) }
        function close(): void { if (bar.item) bar.item.closeAll() }
    }

    LazyLoader {
        id: bar
        active: shell.chosen && !shell.stopped

        Scope {
            id: root

            WatchedShared { id: nameFile; path: HyprShared.state + "/bar-style" }
            WatchedShared {
                id: lookFile
                path: shell.standalone ? ownStyle.path : Quickshell.shellPath("../Modern/quickshellbar/" + (nameFile.text().trim() || "default") + "/config.json")
            }
            readonly property var look: {
                const d = { left: ["user", "workspaces"], center: ["media", "date", "timer", "clock"],
                    right: ["tray", "|", "updates", "network", "audio", "|", "power"],
                    strip: false, background: true, attached: false, height: 30, gap: 6, shape: "round" }
                try { return Object.assign(d, JSON.parse(lookFile.text())) } catch (e) { return d }
            }

            readonly property bool standalone: shell.standalone
            readonly property int pillH: look.height
            readonly property int edge: look.gap
            readonly property bool attached: look.attached === true && !look.strip
            readonly property real flare: !(attached || look.strip) || look.shape === "square" ? 0
                : look.shape === "capsule" ? pillH / 2 : Math.min(Theme.rounding, pillH / 2)
            readonly property int reserve: pillH + edge * (attached ? 1 : 2)

            function run(cmd) { HyprShared.run(cmd) }

            function pillFor(page) {
                const w = windows[Hyprland.focusedMonitor?.name ?? ""]
                return w ? w.pills.find(p => p.visible && p.has(page)) ?? null : null
            }
            function open(page, tab) {
                const p = pillFor(page)
                if (!p) return
                if (tab) { p.show(page); p.tab = tab }
                else p.toggle(page)
            }
            function closeAll() {
                for (const k of Object.keys(windows)) for (const p of windows[k].pills) p.close()
            }
            property var windows: ({})

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }
            readonly property date now: clock.date

            CountdownShared {
                id: countdown
                onFinished: {
                    const p = root.pillFor("alarm")
                    if (p) p.show("alarm")
                    else root.run("notify-send -e -a 'Focus timer' -i alarm-symbolic 'Time is up' " +
                                  "'Your " + words(total) + " session has finished.'")
                }
            }
            readonly property alias timer: countdown

            ForecastShared { id: forecast }
            readonly property alias weather: forecast

            readonly property int updates: UpdatesShared.count

            readonly property var players: MediaShared.players
            property string pinned: ""
            readonly property var player: MediaShared.pickPlayer(pinned)
            NowPlayingShared { id: nowPlaying; player: root.player }
            readonly property alias track: nowPlaying
            readonly property bool playing: MediaShared.playing(player)
            property bool hasMedia: false
            onPlayingChanged: {
                if (playing) { stopped.stop(); hasMedia = true }
                else stopped.restart()
            }
            onPlayerChanged: if (!player) { stopped.stop(); hasMedia = false }
            Component.onCompleted: hasMedia = playing
            Timer { id: stopped; interval: 3000; onTriggered: root.hasMedia = root.playing }
            Binding { target: MediaShared; property: "side"; value: (root.look.left || []).includes("media") ? "left" : (root.look.right || []).includes("media") ? "right" : "center" }
            Connections {
                target: MediaShared
                function onCardChanged() { if (!MediaShared.card && !root.playing) { stopped.stop(); root.hasMedia = false } }
            }

            function cyclePlayer() {
                const ps = players
                if (!ps || ps.length < 2) return
                pinned = ps[(ps.indexOf(player) + 1) % ps.length].dbusName
            }

            WatchedShared {
                id: musicFile
                path: Quickshell.env("XDG_RUNTIME_DIR") + "/music-player.json"
            }
            readonly property var music: {
                try { return JSON.parse(musicFile.text()) } catch (e) { return { open: false } }
            }
            readonly property bool musicOut: !!music.open

            function mediaAway(pill) {
                return musicOut && !pill.tucked
            }
            function showMedia(pill) {
                return hasMedia && !mediaAway(pill) && !(pill.page === "island" && !pill.onRow)
                    && !(MediaShared.card && !pill.open)
            }

            function musicInTheWay(pill, page) {
                const m = music
                if (!m.open || m.tucked || !pill.screen || m.screen !== pill.screen.name || m.x === undefined) return false
                const w = Math.max(pill.rowW, Math.min(pill.maxW, pill.widths[page] ?? 340))
                const p = pill.mapToItem(null, 0, 0)
                const x = pill.align === "left" ? p.x : pill.align === "right" ? p.x + pill.rowW - w : p.x + (pill.rowW - w) / 2
                const my = reserve + m.y, side = m.side || 0
                return m.x < x + w && m.x + side > x && my < p.y + pillH + 460 && my + side > p.y
            }

            function musicCall(call) { if (!standalone) run(HyprShared.util + "/session/shells.sh music " + call) }

            function toggleOverview() {
                Quickshell.execDetached(["qs", "-p", Quickshell.shellDir, "ipc", "call", "overview", "toggle"])
            }

            Workspaces {
                id: spaces
                active: Object.keys(root.windows).some(k => root.windows[k].pills.some(p => p.shownPage === "workspaces"))
            }
            readonly property alias expose: spaces

            Variants {
                model: Quickshell.screens

                PanelWindow {
                    id: win

                    required property var modelData
                    screen: modelData

                    anchors {
                        top: true
                        left: true
                        right: true
                    }
                    implicitHeight: Math.min(modelData.height, root.reserve + 960)
                    exclusiveZone: root.reserve
                    color: "transparent"
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "quickshell-bar"
                    WlrLayershell.keyboardFocus: pills.some(p => p.holdOpen) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                    mask: Region {
                        item: left.visible ? left.card : null
                        Region { item: center.visible ? center.card : null }
                        Region { item: right.visible ? right.card : null }
                    }

                    readonly property var pills: [left, center, right]

                    Component.onCompleted: root.windows = Object.assign({}, root.windows, { [modelData.name]: win })
                    Component.onDestruction: {
                        const w = Object.assign({}, root.windows)
                        delete w[modelData.name]
                        root.windows = w
                    }

                    readonly property real inset: root.look.strip ? root.edge + 2 * root.flare : root.edge + 4 + root.flare
                    readonly property real gap: 8
                    readonly property real leftEnd: left.visible ? left.x + left.width : 0
                    readonly property real rightStart: right.visible ? right.x : width
                    readonly property string stripPath: {
                        if (!root.look.strip) return ""
                        const S = root.reserve - 0.5, r = root.flare, W = width
                        let d = `M -1 -2 L -1 ${S - r} A ${r} ${r} 0 0 0 ${r - 1} ${S}`
                        for (const p of pills) {
                            if (!p.visible) continue
                            const x0 = p.x + p.card.x + 0.5, x1 = x0 + p.card.width - 1, B = p.y + p.card.height - 0.5
                            const depth = B - S
                            if (depth <= 0) continue
                            const k = Math.min(r, depth / 2)
                            d += ` L ${x0 - k} ${S} A ${k} ${k} 0 0 1 ${x0} ${S + k} L ${x0} ${B - k} A ${k} ${k} 0 0 0 ${x0 + k} ${B}`
                               + ` L ${x1 - k} ${B} A ${k} ${k} 0 0 0 ${x1} ${B - k} L ${x1} ${S + k} A ${k} ${k} 0 0 1 ${x1 + k} ${S}`
                        }
                        return d + ` L ${W + 1 - r} ${S} A ${r} ${r} 0 0 0 ${W + 1} ${S - r} L ${W + 1} -2 Z`
                    }
                    readonly property real centerRoom: left.visible || right.visible
                        ? width - 2 * Math.max(leftEnd, width - rightStart) - 2 * gap : width - 2 * inset

                    FocusScope {
                        anchors.fill: parent
                        focus: true
                        Keys.onEscapePressed: { for (const p of win.pills) p.close() }

                        Item {
                            visible: root.look.strip === true
                            anchors.fill: parent
                            opacity: Theme.surface(0.6)
                            layer.enabled: visible

                            Shape {
                                anchors.fill: parent
                                preferredRendererType: Shape.CurveRenderer
                                ShapePath {
                                    strokeWidth: 1
                                    strokeColor: Qt.tint(Theme.bg, Theme.alpha(Theme.fg, 0.12))
                                    fillColor: Theme.bg
                                    PathSvg { path: win.stripPath }
                                }
                            }
                        }

                        Pill {
                            id: left
                            ctx: root
                            screen: win.modelData
                            modules: root.look.left || []
                            align: "left"
                            x: win.inset
                            maxW: (center.visible ? center.x : win.rightStart) - win.gap - x
                            hurry: center.open || right.open
                        }

                        Pill {
                            id: center
                            ctx: root
                            screen: win.modelData
                            modules: root.look.center || []
                            align: "center"
                            x: (win.width - width) / 2
                            maxW: win.centerRoom
                            hurry: left.open || right.open
                        }

                        Pill {
                            id: right
                            ctx: root
                            screen: win.modelData
                            modules: root.look.right || []
                            align: "right"
                            x: win.width - width - win.inset
                            maxW: x + width - (center.visible ? center.x + center.width : win.leftEnd) - win.gap
                            hurry: left.open || center.open
                        }
                    }
                }
            }
        }
    }
}
