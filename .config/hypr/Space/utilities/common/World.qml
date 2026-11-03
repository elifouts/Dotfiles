pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// the planet you're on and where each workspace sits on the map
Singleton {
    id: root

    property real hue: 0.58
    property real seed: 17
    // the land you stand on, apart from the galaxy seed so landing never reshuffles the stars
    property real landSeed: 17
    // nine real colour themes. c = background, foreground, gray, then six accents: red green yellow blue purple cyan.
    // every planet picks one of the accents from the themes switched on, unless random is on
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
    property var pool: themes.map(t => t.id)
    property bool random: false
    readonly property var active: themes.filter(t => pool.indexOf(t.id) >= 0)
    // a theme's pinned accent (index into its colours, 3..8). a pinned theme only ever offers that one
    property var pins: ({})
    // the theme the current colours came from, so two themes sharing a hue never get mixed up
    property string curTheme: ""
    signal poolChanged2()
    // ws id -> [x, y, z, hue]
    property var stars: ({})
    signal landed()

    FileView {
        id: file
        path: Hypr.home + "/.config/space/world.json"
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                const w = JSON.parse(text())
                root.hue = w.hue ?? root.hue
                root.seed = w.seed ?? root.seed
                root.landSeed = w.landSeed ?? root.seed
                root.stars = w.stars ?? {}
                root.pins = w.pins ?? ({})
                if (Array.isArray(w.pool)) { const k = w.pool.filter(x => root.themes.some(t => t.id === x)); if (k.length) root.pool = k }
                root.random = !!w.random
                // older saves never wrote it, work it out from the hue
                root.curTheme = w.curTheme || (root.random ? "" : root.themeFor(root.hue)?.t.id ?? "")
            } catch (e) {}
        }
    }
    function save() { file.setText(JSON.stringify({ hue: hue, seed: seed, landSeed: landSeed, stars: stars, pool: pool, pins: pins, curTheme: curTheme, random: random })) }

    // every accent the pool can hand out, as [theme, colour index]
    function offers() {
        const out = []
        for (const t of active) {
            const p = pins[t.id]
            if (p !== undefined) out.push([t, p])
            else for (let i = 3; i < 9; i++) out.push([t, i])
        }
        return out
    }
    // a 0..1 roll becomes the hue of one accent from the enabled themes (or stays itself when random)
    // away skips the theme you're on, the star map's undiscovered systems use it so finding one is always a new look
    function snap(r, away) {
        const all = offers(), other = away ? all.filter(k => k[0].id !== curTheme) : all, a = other.length ? other : all
        if (random || a.length === 0) return r
        const k = a[Math.min(a.length - 1, Math.floor(r * a.length))]
        return accentHue(k[0].c[k[1]])
    }
    // the offered accent closest to a hue
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
    // pin one of a theme's accents as its accent, or click it again to let planets use all six
    function pin(id, i) {
        const p = Object.assign({}, pins)
        const was = p[id] === i
        if (was) delete p[id]
        else p[id] = i
        pins = p
        poolChanged2()
        if (!was && themeOn(id)) use(id, i)
        else save()
    }
    // the theme and accent a hue came from
    function themeFor(h) {
        const list = (active.length ? active : themes).slice().sort((x, y) => (y.id === curTheme) - (x.id === curTheme))
        let best = null, bi = 3, d = 9
        for (const t of list) for (let i = 3; i < 9; i++) {
            const x = Math.abs(accentHue(t.c[i]) - h), dd = Math.min(x, 1 - x)
            if (dd < d - 1e-9) { d = dd; best = t; bi = i }
        }
        return d < 0.002 ? { t: best, i: bi } : null
    }
    // the theme and accent in use right now, null when random made up its own
    readonly property var applied: random || !curTheme ? null : themeFor(hue)
    // put one theme's accent on the current system and the whole desktop
    function use(id, i) {
        const t = themes.find(x => x.id === id)
        curTheme = id
        recolor(accentHue(t.c[i]))
    }
    function themeOn(id) { return pool.indexOf(id) >= 0 }
    // flip a theme in the pool, never emptying it. turning one on lands you on it
    function toggleTheme(id) {
        const on = themeOn(id)
        if (on && pool.length === 1) return
        pool = on ? pool.filter(x => x !== id) : pool.concat([id])
        if (on) { curTheme = ""; recolor(nearest(hue)) }
        else use(id, pins[id] ?? 6)
        poolChanged2()
    }
    function setRandom(v) {
        random = v
        save()
        poolChanged2()
        if (!v) recolor(nearest(hue))
    }

    // workspaces nobody placed get a spot on a loose spiral round the start
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

    // remembers which theme a hue came from, so settings can say what's applied and two themes sharing a hue stay apart
    function settle(h) {
        hue = h
        const f = random ? null : themeFor(h)
        curTheme = f ? f.t.id : ""
    }
    readonly property var accentNames: ["", "", "", "red", "green", "yellow", "blue", "purple", "cyan"]
    // same land, new colors
    function recolor(h) {
        settle(h)
        paint(h)
        scheme.setText(JSON.stringify(palette(hue)))
        save()
    }
    // the system you're standing in keeps the colour you picked, so the map shows it the same
    function paint(h) {
        const id = Hyprland.focusedWorkspace?.id
        if (id > 0) stars = Object.assign({}, stars, { [id]: starOf(id).slice(0, 3).concat([h]) })
    }
    // a fresh planet: new terrain, new colors for the whole theme
    function reroll(h, s) {
        settle(h ?? snap(Math.random()))
        if (h === undefined) paint(hue)
        if (s === undefined) { seed = Math.round(Math.random() * 997); landSeed = seed }
        else landSeed = s
        scheme.setText(JSON.stringify(palette(hue)))
        save()
        landed()
    }

    // 16 colors from one hue, laid out like pywal's
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

    // color-apply.sh does the rest: wal, kitty, borders, everything that reads pywal
    FileView {
        id: scheme
        path: Hypr.home + "/.config/wal/colorschemes/dark/space.json"
        atomicWrites: true
        printErrors: false
        onSaved: Store.applyTheme("dark/space")
    }
}
