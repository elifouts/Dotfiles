pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: home + "/.config/hypr"
    readonly property string util: dir + "/utilities"
    readonly property string state: dir + "/state"
    readonly property var workspaces: Hyprland.workspaces.values.filter(w => w.id > 0)
    readonly property var workspaceIds: {
        const s = new Set([1, 2, 3, 4, 5])
        for (const w of workspaces) s.add(w.id)
        return [...s].sort((a, b) => a - b)
    }

    FileView {
        id: luaFile
        path: root.dir + "/hyprland.lua"
        blockLoading: true
        printErrors: false
    }
    readonly property bool lua: luaFile.text() !== ""

    function dispatch(lua, classic) {
        Hyprland.dispatch(root.lua ? lua : classic)
    }

    function focusWs(id) { Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })") }

    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd])
    }

    function locate(done) {
        located.push(done)
        cursorQuery.running = true
    }
    function screenAt(x, y) {
        return Quickshell.screens.find(s => x >= s.x && x < s.x + s.width && y >= s.y && y < s.y + s.height) ?? focusedScreen()
    }
    function focusedScreen() {
        return Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    }
    readonly property var moonScreen: Quickshell.screens.reduce((a, b) => b.width > a.width ? b : a, Quickshell.screens[0])
    function rateOf(screen) { return Hyprland.monitorFor(screen)?.lastIpcObject?.refreshRate ?? 0 }
    readonly property var fastScreen: Quickshell.screens.reduce((a, b) => rateOf(b) > rateOf(a) + 1 ? b : a, Quickshell.screens[0])
    readonly property real fastMs: 1000 / (rateOf(fastScreen) || 60)
    Component.onCompleted: Hyprland.refreshMonitors()
    Connections { target: Quickshell; function onScreensChanged() { Hyprland.refreshMonitors() } }
    function scaleFor(s) {
        return s ? Math.max(0.8, Math.min(1.35, Math.min(s.width / 1920, s.height / 1080))) : 1
    }
    property var located: []
    function found(c) {
        const scr = c ? screenAt(c.x, c.y) : screenAt(-1, -1)
        const done = located
        located = []
        done.forEach(f => f(scr))
    }
    Process {
        id: cursorQuery
        command: ["hyprctl", "-j", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                let c = null
                try { c = JSON.parse(text) } catch (e) {}
                root.found(c)
            }
        }
        onExited: code => { if (code !== 0) root.found(null) }
    }
}
