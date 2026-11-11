pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../shared"

Singleton {
    id: root

    property real hue: 0.58
    property real seed: 17
    property real landSeed: 17
    readonly property var themes: [
        { id: "everforest", name: "everforest", c: ["#2d353b", "#d3c6aa", "#475258", "#e67e80", "#a7c080", "#dbbc7f", "#7fbbb3", "#d699b6", "#83c092"] },
        { id: "gruvbox", name: "gruvbox", c: ["#282828", "#ebdbb2", "#665c54", "#fb4934", "#b8bb26", "#fabd2f", "#83a598", "#d3869b", "#8ec07c"] },
        { id: "nord", name: "nord", c: ["#2e3440", "#d8dee9", "#4c566a", "#bf616a", "#a3be8c", "#ebcb8b", "#81a1c1", "#b48ead", "#88c0d0"] },
        { id: "catppuccin", name: "catppuccin", c: ["#24273a", "#cad3f5", "#5b6078", "#ed8796", "#a6da95", "#eed49f", "#8aadf4", "#c6a0f6", "#8bd5ca"] },
        { id: "tokyonight", name: "tokyo night", c: ["#24283b", "#c0caf5", "#565f89", "#f7768e", "#9ece6a", "#e0af68", "#7aa2f7", "#bb9af7", "#7dcfff"] },
        { id: "rosepine", name: "rosé pine", c: ["#191724", "#e0def4", "#524f67", "#eb6f92", "#9ccfd8", "#f6c177", "#31748f", "#c4a7e7", "#ebbcba"] },
        { id: "dracula", name: "dracula", c: ["#282a36", "#f8f8f2", "#6272a4", "#ff5555", "#50fa7b", "#f1fa8c", "#8be9fd", "#bd93f9", "#ff79c6"] },
        { id: "kanagawa", name: "kanagawa", c: ["#1f1f28", "#dcd7ba", "#54546d", "#e82424", "#98bb6c", "#e6c384", "#7e9cd8", "#957fb8", "#7aa89f"] },
        { id: "solarized", name: "solarized", c: ["#002b36", "#93a1a1", "#586e75", "#dc322f", "#859900", "#b58900", "#268bd2", "#6c71c4", "#2aa198"] }
    ]
    function accentHue(hex) { return Qt.color(hex).hslHue }
    property bool random: false
    property var pins: ({})
    property string curTheme: ""
    signal offersChanged()
    property var stars: ({})
    property bool heldReload: false
    Connections {
        target: Ui
        function onHoldThemeChanged() {
            if (Ui.holdTheme || !root.heldReload) return
            root.heldReload = false
            Quickshell.execDetached(["hyprctl", "reload", "config-only"])
        }
    }
    signal hopped()
    property bool hopPending: false
    property bool hopFresh: false
    property real hopHue: -1
    property bool hopBusy: false
    property real hopProg: 0
    property bool hopSwapped: false
    property bool hopRushing: false
    function ease(x) { return (1 - Math.cos(Math.PI * Math.max(0, Math.min(1, x)))) / 2 }
    readonly property real hopAfter: hopSwapped ? Math.max(0, (hopProg - 0.3) / 0.7) : 0
    readonly property real hopTravel: 1.2 * ease(hopProg)
    onHopProgChanged: {
        if (!hopBusy || hopSwapped || hopProg < 0.3) return
        hopSwapped = true
        hopLand()
    }
    property var clock: null
    PaceShared {
        id: hopRun
        duration: Theme.ms(root.hopRushing ? 220 : 1300)
        clock: root.clock
        frameMs: HyprShared.fastMs
        onValueChanged: root.hopProg = value
        onDone: {
            root.hopRushing = false
            root.hopBusy = false
            Ui.holdTheme = false
        }
    }
    function hop(fresh) {
        if (hopBusy) {
            if (hopRushing) return
            hopRushing = true
            hopRun.from = hopProg
            hopRun.play()
            return
        }
        if (Ui.holdTheme) return
        hopStart(!!fresh)
    }
    function hopStart(fresh) {
        hopHue = snap(Math.random(), true)
        hopFresh = fresh
        hopPending = true
        hopBusy = true
        Ui.holdTheme = true
        hopped()
        hopSwapped = false
        hopRun.from = 0
        hopRun.play()
    }
    function hopLand() {
        if (!hopPending) return
        hopPending = false
        if (hopHue >= 0) recolor(hopHue)
        landSeed = Math.round(Math.random() * 997)
        if (hopFresh) {
            seed = landSeed
            commit()
        }
        save()
    }

    FileView {
        id: file
        path: HyprShared.home + "/.config/space/world.json"
        atomicWrites: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                if (text() === root.written) return
                const w = JSON.parse(text())
                root.hue = w.hue ?? root.hue
                root.seed = w.seed ?? root.seed
                root.landSeed = w.landSeed ?? root.seed
                root.stars = w.stars ?? {}
                root.pins = w.pins ?? ({})
                root.random = !!w.random
                root.curTheme = w.curTheme || (root.random ? "" : root.themeFor(root.hue)?.t.id ?? "")
                root.repaint = !!w.restored
                root.flushRepaint()
            } catch (e) {}
        }
    }
    property bool repaint: false
    function flushRepaint() {
        if (!repaint || !(Hyprland.focusedWorkspace?.id > 0)) return
        repaint = false
        paint(hue)
        save()
    }
    Connections { target: Hyprland; function onFocusedWorkspaceChanged() { root.flushRepaint() } }
    property string written: ""
    function save() {
        written = JSON.stringify({ hue: hue, seed: seed, landSeed: landSeed, stars: stars, pins: pins, curTheme: curTheme, random: random })
        file.setText(written)
    }
    function commit() {
        StoreShared.set("space.world", { theme: curTheme, hue: hue, random: random, palette: palette(hue) })
    }

    function offers() {
        const out = []
        for (const t of themes) {
            const p = pins[t.id]
            if (p !== undefined) out.push([t, p])
            else for (let i = 3; i < 9; i++) out.push([t, i])
        }
        return out
    }
    function snap(r, away) {
        const all = offers(), other = away ? all.filter(k => k[0].id !== curTheme) : all, a = other.length ? other : all
        if (random || a.length === 0) return r
        const k = a[Math.min(a.length - 1, Math.floor(r * a.length))]
        return accentHue(k[0].c[k[1]])
    }
    function nearest(h) {
        const a = offers()
        if (random || a.length === 0) return h
        let best = h, d = 9
        for (const k of a) {
            const v = accentHue(k[0].c[k[1]]), x = Math.abs(v - h), dd = Math.min(x, 1 - x)
            if (dd < d) { d = dd; best = v }
        }
        return best
    }
    function pin(id, i) {
        const p = Object.assign({}, pins)
        const was = p[id] === i
        if (was) delete p[id]
        else p[id] = i
        pins = p
        offersChanged()
        if (!was) use(id, i)
        else save()
    }
    function themeFor(h) {
        const list = themes.slice().sort((x, y) => (y.id === curTheme) - (x.id === curTheme))
        let best = null, bi = 3, d = 9
        for (const t of list) for (let i = 3; i < 9; i++) {
            const x = Math.abs(accentHue(t.c[i]) - h), dd = Math.min(x, 1 - x)
            if (dd < d - 1e-9) { d = dd; best = t; bi = i }
        }
        return d < 0.002 ? { t: best, i: bi } : null
    }
    readonly property var applied: random || !curTheme ? null : themeFor(hue)
    function use(id, i) {
        const t = themes.find(x => x.id === id)
        random = false
        curTheme = id
        recolor(accentHue(t.c[i]))
        offersChanged()
        commit()
    }
    function setRandom(v) {
        random = v
        save()
        offersChanged()
        if (!v) recolor(nearest(hue))
        commit()
    }

    function starOf(id) {
        const s = stars[id]
        if (s) return s
        const a = id * 2.4
        return [Math.cos(a) * (60 + id * 22), Math.sin(id * 1.3) * 26, Math.sin(a) * (60 + id * 22), hue]
    }
    function place(id, pos, h) {
        stars = Object.assign({}, stars, { [id]: [pos[0], pos[1], pos[2], h] })
        save()
    }

    function settle(h) {
        hue = h
        const f = random ? null : themeFor(h)
        curTheme = f ? f.t.id : ""
    }
    readonly property var accentNames: ["", "", "", "red", "green", "yellow", "blue", "purple", "cyan"]
    function recolor(h) {
        hopHue = -1
        settle(h)
        paint(h)
        scheme.setText(JSON.stringify(palette(hue)))
        Theme.saved = palette(hue)
        save()
    }
    function reland() {
        landSeed = Math.round(Math.random() * 997)
        seed = landSeed
        save()
    }
    function paint(h) {
        const id = Hyprland.focusedWorkspace?.id
        if (id > 0) stars = Object.assign({}, stars, { [id]: starOf(id).slice(0, 3).concat([h]) })
    }
    function reroll(h, s) {
        settle(h ?? snap(Math.random()))
        if (h === undefined) paint(hue)
        if (s === undefined) { seed = Math.round(Math.random() * 997); landSeed = seed }
        else landSeed = s
        scheme.setText(JSON.stringify(palette(hue)))
        save()
    }

    function palette(h) {
        const f = random ? null : themeFor(h)
        if (f) {
            const c = f.t.c, colors = { color0: c[0], color7: c[1], color8: c[2], color15: c[1] }
            for (let i = 0; i < 6; i++) { colors["color" + (i + 1)] = c[3 + i]; colors["color" + (i + 9)] = c[3 + i] }
            colors.color9 = c[f.i]
            colors.color13 = c[3 + (f.i - 3 + 4) % 6]
            return { name: "Space", custom: true, colors: colors, special: { background: c[0], foreground: c[1], cursor: c[1] } }
        }
        const c = (dh, s, l) => String(Qt.hsla(((h + dh) % 1 + 1) % 1, s, l, 1))
        const tones = [0, 0.07, 0.14, 0.5, 0.57, -0.08]
        const colors = { color0: c(0, 0.35, 0.06), color7: c(0, 0.14, 0.78), color8: c(0, 0.18, 0.32), color15: c(0, 0.1, 0.94) }
        tones.forEach((t, i) => {
            colors["color" + (i + 1)] = c(t, 0.5, 0.52)
            colors["color" + (i + 9)] = c(t, 0.7, 0.68)
        })
        return { name: "Space", custom: true, colors: colors,
                 special: { background: colors.color0, foreground: colors.color15, cursor: colors.color15 } }
    }

    FileView {
        id: scheme
        path: HyprShared.home + "/.config/wal/colorschemes/dark/space.json"
        atomicWrites: true
        printErrors: false
        onSaved: {
            root.heldReload = Ui.holdTheme
            StoreShared.applyTheme("dark/space", Ui.holdTheme)
        }
    }
}
