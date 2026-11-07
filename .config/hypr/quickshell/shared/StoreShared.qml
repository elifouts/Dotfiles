pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../style/common/Schema.js" as Schema

Singleton {
    id: root

    readonly property string util: HyprShared.util
    readonly property string py: util + "/settings/hypr-settings.py"

    property var values: ({})
    property var styles: ({})
    property var active: ({ style: "", variant: "" })
    property var themes: []
    property string colorTheme: "pywal"
    property string wallpaper: ""
    property var cursors: []
    property var waybar: ({ styles: [], active: "" })
    property string waybarActive: ""
    property string bar: "waybar"
    property var quickshell: ({ styles: [], active: "" })
    property string quickshellActive: ""
    property var caps: ({})
    property var pywalPalette: []
    property var saved: ({ entries: [], active: "default" })
    property var pending: ({})
    property var picker: null
    property int opened: 0
    property string lastSnapshot: ""
    property bool refreshAfter: false

    function refresh() {
        if (!stateProc.running) {
            stateProc.command = ["python3", py, "state"].concat(Schema.keys())
            stateProc.running = true
        }
    }

    function set(key, value) {
        setMany({ [key]: value })
    }

    function reset(...keys) {
        const entries = {}
        for (const k of keys) entries[k] = null
        setMany(entries)
    }

    function setValues(entries) {
        values = Object.assign({}, values, entries)
    }

    function setMany(entries) {
        const next = Object.assign({}, values)
        for (const key of Object.keys(entries)) {
            if (entries[key] !== null) next[key] = entries[key]
            pending[key] = entries[key]
            if (entries[key] === null) refreshAfter = true
        }
        values = next
        flushTimer.restart()
    }

    function flush() {
        if (setProc.running) return
        const keys = Object.keys(pending)
        if (keys.length === 0) {
            if (refreshAfter) { refreshAfter = false; lastSnapshot = ""; refresh() }
            return
        }
        const args = keys.map(k => k + "=" + JSON.stringify(pending[k]))
        pending = {}
        setProc.command = ["python3", py, "set"].concat(args)
        setProc.running = true
    }

    function applyProfile(style, variant) {
        active = { style: style, variant: variant }
        Quickshell.execDetached(["setsid", "-f", util + "/settings/hypr-profile.sh", "apply", style, variant])
    }

    signal themeApplied()
    property string queuedTheme: ""
    function applyTheme(id, noReload) {
        colorTheme = id
        setMany({ "colors.theme": id })
        if (themeProc.running) return queuedTheme = id
        themeProc.command = ["env", "COLOR_NO_RELOAD=" + (noReload ? "1" : ""), "setsid", "-w", util + "/colors/color-apply.sh", id]
        themeProc.running = true
    }
    Process {
        id: themeProc
        onExited: {
            const next = root.queuedTheme
            root.queuedTheme = ""
            if (next) root.applyTheme(next)
            else root.themeApplied()
        }
    }

    function applyWaybar(id) {
        waybarActive = id
        Quickshell.execDetached(["env", "HYPR_SETTINGS_NO_RECORD=1", "setsid", "-f", util + "/bars/waybar-style.sh", "apply", id])
        setMany({ "waybar.style": id })
    }

    function applyQuickshell(id) {
        quickshellActive = id
        Quickshell.execDetached(["env", "HYPR_SETTINGS_NO_RECORD=1", "setsid", "-f", util + "/bars/bar.sh", "style", id])
        setMany({ "quickshell.style": id })
    }

    function applyBar(id) {
        bar = id
        Quickshell.execDetached(["env", "HYPR_SETTINGS_NO_RECORD=1", "setsid", "-f", util + "/bars/bar.sh", "apply", id])
        if (id === "quickshell") {
            waybarActive = "default"
            setMany({ "bar.kind": id, "waybar.style": "default" })
        } else setMany({ "bar.kind": id })
    }

    function savedRun(action, name) {
        if (savedProc.running) return
        savedProc.command = ["python3", py, "saved", action].concat(name ? [name] : [])
        savedProc.running = true
    }

    function saveUi(key, value) {
        Quickshell.execDetached(["python3", py, "ui", key + "=" + JSON.stringify(value)])
    }

    Timer { id: flushTimer; interval: 40; onTriggered: root.flush() }

    Process {
        id: setProc
        onExited: {
            if (root.saved.active === "default") root.refreshAfter = true
            root.flush()
        }
    }

    Process {
        id: savedProc
        onExited: { root.lastSnapshot = ""; root.refresh() }
    }

    WatchedShared { path: HyprShared.state + "/profile"; onLoaded: staleTimer.restart() }
    WatchedShared { path: Quickshell.env("HOME") + "/.cache/wallpaper-picker/current"; onLoaded: staleTimer.restart() }
    WatchedShared { path: Quickshell.env("HOME") + "/.cache/wal/colors.json"; onLoaded: staleTimer.restart() }
    Timer { id: staleTimer; interval: 300; onTriggered: root.refresh() }

    Process {
        id: stateProc
        stdout: StdioCollector {
            onStreamFinished: {
                let data
                try { data = JSON.parse(text) } catch (e) { return }
                const snapshot = text
                if (snapshot === root.lastSnapshot) return
                root.lastSnapshot = snapshot
                if (Object.keys(root.pending).length === 0 && !setProc.running) root.values = data.values
                root.styles = data.styles
                root.active = data.active
                root.themes = data.themes
                root.colorTheme = data.colorTheme
                root.wallpaper = data.wallpaper
                root.cursors = data.cursors
                root.waybar = data.waybar
                root.waybarActive = data.waybar.active
                root.bar = data.bar || "waybar"
                root.quickshell = data.quickshell || { styles: [], active: "" }
                root.quickshellActive = root.quickshell.active
                root.caps = data.caps
                root.pywalPalette = data.pywalPalette
                root.saved = data.saved || { entries: [], active: "default" }
            }
        }
    }
}
