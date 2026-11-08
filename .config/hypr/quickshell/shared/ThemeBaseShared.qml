import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property string sans: "CodeNewRoman Nerd Font Propo"
    readonly property int pad: 14

    property real hyprRounding: 10
    property real rounding: hyprRounding
    property real round: 1
    property real lines: 0
    property int caps: Font.MixedCase
    property int menuRow: 40
    property real tracking: 0
    property real gapsOut: 8
    property bool hyprAnimates: true
    property real hyprPace: 1
    property var hyprSettle: own
    property var hyprLeave: own
    function utility(key, fallback) {
        const m = settingsFile.text().match(new RegExp('\\["utilities"\\]\\s*=\\s*\\{[^}]*\\["' + key + '"\\]\\s*=\\s*([\\w.]+)'))
        return m ? m[1] : fallback
    }
    readonly property bool ownMotion: utility("animations") === "true"
    property bool clock24Default: false
    readonly property bool h24: utility("clock24", String(clock24Default)) === "true"
    readonly property real shellOpacity: parseFloat(utility("opacity", "1"))
    function surface(a) { return Math.min(1, a * shellOpacity) }
    function back(a) { return alpha(bg, surface(a)) }
    function clock(date, seconds, mark) {
        const time = (seconds ? ":mm:ss" : ":mm")
        if (h24) return Qt.formatTime(date, "HH" + time)
        const twelve = Qt.formatTime(date, "h" + time + " " + (mark || "AP"))
        return mark ? twelve : twelve.split(" ")[0]
    }

    readonly property var own: [0.2, 0.9, 0.3, 1, 1, 1]
    readonly property bool animates: ownMotion || hyprAnimates
    readonly property real pace: ownMotion ? 1 : hyprPace
    readonly property var settle: ownMotion ? own : hyprSettle
    readonly property var leave: ownMotion ? own : hyprLeave
    readonly property int fast: ms(160)
    readonly property int move: ms(280)
    readonly property int quick: ms(180)
    readonly property int slow: ms(560)

    function r(px) {
        return px * rounding / 10
    }

    function seg(t, delay) {
        return Math.max(0, Math.min(1, (t - delay) / (1 - delay)))
    }

    function ms(d) {
        return animates ? Math.round(d * pace) : 0
    }

    function refresh() {
        optionProc.running = true
        curveProc.running = true
    }
    Component.onCompleted: refresh()

    Process {
        id: optionProc
        command: ["sh", "-c", "hyprctl -j getoption decoration:rounding; hyprctl -j getoption animations:enabled; hyprctl -j getoption general:gaps_out"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const [r, a, g] = text.trim().split(/\n(?=\{)/).map(s => JSON.parse(s))
                    if (typeof r.int === "number") root.hyprRounding = r.int
                    root.hyprAnimates = a.bool ?? a.int !== 0
                    const n = parseInt(String(g.custom ?? g.css ?? g.int ?? "").trim().split(/\s+/)[0])
                    if (!isNaN(n)) root.gapsOut = n
                } catch (e) {}
            }
        }
    }

    Process {
        id: curveProc
        command: ["hyprctl", "-j", "animations"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const [leaves, beziers] = JSON.parse(text)
                    const parent = { windowsIn: "windows", windowsOut: "windows", windows: "global" }
                    const leaf = (name, has) => {
                        for (let n = name; n; n = parent[n]) {
                            const l = leaves.find(a => a.name === n)
                            if (l && has(l)) return l
                        }
                        return null
                    }
                    const curve = name => {
                        const l = leaf(name, l => !!l.bezier && beziers.some(b => b.name === l.bezier))
                        const b = l ? beziers.find(b => b.name === l.bezier) : null
                        return b ? [b.X0, b.Y0, b.X1, b.Y1, 1, 1] : null
                    }
                    root.hyprSettle = curve("windowsIn") ?? root.own
                    root.hyprLeave = curve("windowsOut") ?? root.hyprSettle
                    const w = leaf("windowsIn", l => l.speed > 0)
                    root.hyprPace = w ? Math.max(0.2, Math.min(3, w.speed / 3)) : 1
                } catch (e) {}
            }
        }
    }

    FileView {
        id: settingsFile
        path: HyprShared.state + "/settings.lua"
        watchChanges: true
        printErrors: false
        onFileChanged: { reload(); settleTimer.n = 0; settleTimer.restart() }
    }
    Timer {
        id: settleTimer
        property int n: 0
        interval: 250
        repeat: true
        onTriggered: { root.refresh(); if (++n >= 3) stop() }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) { if (event.name === "configreloaded") root.refresh() }
    }

    property bool frozen: false
    onFrozenChanged: if (!frozen) reload()
    function reload() { if (!frozen) { walFile.reload(); rolesFile.reload() } }
    WatchedShared {
        id: walFile
        watchChanges: !root.frozen
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        onLoaded: { try { root.saved = JSON.parse(text()) } catch (e) {} }
    }

    property var saved: null
    property var preview: null
    readonly property var wal: preview ? {
        colors: preview.reduce((o, c, i) => (o["color" + i] = c, o), {}),
        special: { background: preview[0], foreground: preview[15] }
    } : saved
    function c(i, fallback) { return wal ? wal.colors["color" + i] : fallback }
    readonly property color red: c(9, "#e06c75")
    readonly property color green: c(10, "#98c379")
    readonly property color yellow: c(11, "#e5c07b")
    readonly property color blue: c(12, "#8fd3ff")
    readonly property color magenta: c(13, "#c3a6ff")
    readonly property color cyan: c(14, "#9fe0d0")

    WatchedShared { id: rolesFile; watchChanges: !root.frozen; path: HyprShared.state + "/color-roles.json" }
    readonly property var roles: { try { return JSON.parse(rolesFile.text()) } catch (e) { return {} } }
    readonly property var roleSlots: ({ accent: 9, accent2: 13, ok: 10, caution: 11, info: 14, warn: 1 })
    function slotOf(role) { return roles[role] ?? roleSlots[role] }
    function setRole(role, slot) {
        Quickshell.execDetached([HyprShared.util + "/colors/color-roles.sh"].concat(role ? ["set", role, String(slot)] : ["reset"]))
    }
    readonly property color accent: c(slotOf("accent"), "#8fd3ff")
    readonly property color accent2: c(slotOf("accent2"), magenta)
    readonly property color ok: c(slotOf("ok"), green)
    readonly property color caution: c(slotOf("caution"), yellow)
    readonly property color info: c(slotOf("info"), cyan)
    readonly property color warn: c(slotOf("warn"), "#e06c75")
    property color fg: readable(c(7, "#c7c6c2"))
    readonly property color bright: readable(c(15, "#ffffff"))
    readonly property color dim: alpha(fg, 0.5)
    property color bg: wal ? wal.special.background : "#101418"
    readonly property color panel: back(0.6)
    readonly property color glass: panel
    readonly property color faint: alpha(fg, 0.14)
    readonly property color void_: Qt.darker(bg, 2.2)
    property color edge: alpha(fg, 0.07)

    readonly property var shades: [bg].concat(Array.from({ length: 16 }, (_, i) => Qt.color(c(i, i < 8 ? "#101418" : "#ffffff"))))
    readonly property color darkest: shades.reduce((a, b) => lum(b) < lum(a) ? b : a)
    readonly property color lightest: shades.reduce((a, b) => lum(b) > lum(a) ? b : a)
    function lum(c) {
        const f = v => v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
        return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b)
    }
    function contrast(a, b) {
        const x = lum(a), y = lum(b)
        return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05)
    }
    function against(fill) { return contrast(fill, darkest) >= contrast(fill, lightest) ? darkest : lightest }
    function readable(c) { c = Qt.color(c); return contrast(c, bg) >= 3 ? c : against(bg) }

    function soft(c, hot) { return hot ? Qt.lighter(c, 1.12) : Qt.color(c) }
    function on(fill) { return against(soft(fill)) }
    readonly property color ink: on(accent)
    readonly property var spectrum: [blue, cyan, green, yellow, magenta]

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    function mix(a, b, t) { a = Qt.color(a); b = Qt.color(b); return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }

    function along(stops, f) {
        if (!stops || stops.length === 0) return accent
        if (stops.length === 1) return stops[0]
        const x = Math.max(0, Math.min(1, f)) * (stops.length - 1)
        const i = Math.min(stops.length - 2, Math.floor(x))
        const a = Qt.color(stops[i]), b = Qt.color(stops[i + 1]), m = x - i
        return Qt.rgba(a.r + (b.r - a.r) * m, a.g + (b.g - a.g) * m, a.b + (b.b - a.b) * m, 1)
    }
}
