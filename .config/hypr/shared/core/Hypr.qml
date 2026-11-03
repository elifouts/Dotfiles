pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// hyprland stuff that used to be crammed into Theme
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: home + "/.config/hypr"
    readonly property string util: dir + "/utilities"
    readonly property string state: dir + "/state"

    // lua dispatch if hyprland.lua is in use
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

    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd])
    }

    // focusedMonitor can be stale at startup, so ask for the cursor position
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
    function screenNamed(name) {
        return Quickshell.screens.find(s => s.name === name) ?? focusedScreen()
    }
    // ui scale for the popups, i tuned everything at 1080p
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
