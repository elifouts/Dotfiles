pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "Schema.js" as Schema
import "../common"

// changes show right away and get batched to hypr-settings.py
Singleton {
    id: root

    readonly property string util: Hypr.util
    readonly property string py: util + "/hypr-settings.py"

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
    // the colors page, so the window can drive it from the keyboard
    property var picker: null
    // bumped every time the panel opens so pages replay their Rise
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

    // null removes the key
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
        Quickshell.execDetached(["setsid", "-f", util + "/hypr-profile.sh", "apply", style, variant])
    }

    // one apply at a time, clicking fast used to let an older run finish last and leave the wrong accent up
    signal themeApplied()
    property string queuedTheme: ""
    function applyTheme(id) {
        colorTheme = id
        setMany({ "colors.theme": id })
        if (themeProc.running) return queuedTheme = id
        themeProc.command = ["setsid", "-w", util + "/color-apply.sh", id]
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
        Quickshell.execDetached(["env", "HYPR_SETTINGS_NO_RECORD=1", "setsid", "-f", util + "/waybar-style.sh", "apply", id])
        setMany({ "waybar.style": id })
    }

    function applyQuickshell(id) {
        quickshellActive = id
        Quickshell.execDetached(["env", "HYPR_SETTINGS_NO_RECORD=1", "setsid", "-f", util + "/bar.sh", "style", id])
        setMany({ "quickshell.style": id })
    }

    function applyBar(id) {
        bar = id
        Quickshell.execDetached(["env", "HYPR_SETTINGS_NO_RECORD=1", "setsid", "-f", util + "/bar.sh", "apply", id])
        if (id === "quickshell") {
            waybarActive = "default"
            setMany({ "bar.kind": id, "waybar.style": "default" })
        } else setMany({ "bar.kind": id })
    }

    // action: save NAME | apply ID | delete ID | wipe
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

    // profile or wallpaper changed somewhere else. wal writes a bunch of files at once hence the wait
    Watched { path: Hypr.state + "/profile"; onLoaded: staleTimer.restart() }
    Watched { path: Quickshell.env("HOME") + "/.cache/wallpaper-picker/current"; onLoaded: staleTimer.restart() }
    Watched { path: Quickshell.env("HOME") + "/.cache/wal/colors.json"; onLoaded: staleTimer.restart() }
    Timer { id: staleTimer; interval: 300; onTriggered: root.refresh() }

    Process {
        id: stateProc
        stdout: StdioCollector {
            onStreamFinished: {
                let data
                try { data = JSON.parse(text) } catch (e) { return }
                // skip identical snapshots
                const snapshot = text
                if (snapshot === root.lastSnapshot) return
                root.lastSnapshot = snapshot
                // don't overwrite unflushed edits
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
