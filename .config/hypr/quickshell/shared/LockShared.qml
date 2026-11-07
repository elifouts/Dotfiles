pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pam
import "../style/common"

Singleton {
    id: root

    readonly property string user: Quickshell.env("USER")
    readonly property bool preview: Quickshell.env("LOCK_PREVIEW") === "1"
    readonly property string shots: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-lock"

    readonly property color ink: Theme.lines ? Theme.fg : "#ffffff"
    readonly property color card: Theme.back(0.5)
    readonly property color edge: Theme.edge
    readonly property string wallpaper: {
        const p = walPath.text().trim()
        return p ? "file://" + encodeURI(p) : ""
    }
    FileView { id: walPath; path: HyprShared.home + "/.cache/wal/wal"; printErrors: false }

    function corner(h, u) { return Math.min(h / 2, Theme.rounding * u) }


    property real t: 0
    NumberAnimation { id: tween; target: root; property: "t"; to: 1; duration: Theme.ms(750); easing.type: Easing.OutCubic }
    function enter() { if (!leaving && !tween.running && t < 1) tween.start() }

    property bool leaving: false
    property real out: 0
    property real fade: 1
    signal unlock()
    signal finish()
    function leave() {
        if (leaving) return
        leaving = true
        tween.stop()
        outro.start()
    }
    SequentialAnimation {
        id: outro
        NumberAnimation { target: root; property: "out"; to: 1; duration: Theme.ms(220); easing.type: Easing.InCubic }
        ScriptAction { script: { root.unlock(); if (!root.preview) root.finish() } }
        NumberAnimation { target: root; property: "fade"; to: 0; duration: Theme.ms(450); easing.type: Easing.InOutCubic }
        ScriptAction { script: root.finish() }
    }


    readonly property var defaults: ({ clock: true, greeter: true, music: true, battery: true, power: true, idleHide: true })
    readonly property var labels: [
        ["clock", "Clock"], ["greeter", "Greeter"], ["music", "Music"], ["battery", "Battery"],
        ["power", "Power buttons"], ["idleHide", "Fade on idle"]
    ]
    readonly property string statePath: HyprShared.home + "/.local/state/quickshell-lock.json"
    FileView { id: stateFile; path: root.statePath; printErrors: false; blockLoading: true }
    property var cfg: {
        let saved = {}
        try { saved = JSON.parse(stateFile.text()) } catch (e) {}
        return Object.assign({}, defaults, saved)
    }
    function set(key, value) {
        const c = Object.assign({}, cfg)
        c[key] = value
        cfg = c
        Quickshell.execDetached(["mkdir", "-p", HyprShared.home + "/.local/state"])
        stateFile.setText(JSON.stringify(c, null, 2))
    }
    property bool menuOpen: false


    property string password: ""
    property bool failed: false
    property bool checking: false
    signal rejected()

    function submit() {
        if (checking || password === "") return
        checking = true
        failed = false
        pam.start()
    }

    PamContext {
        id: pam
        configDirectory: HyprShared.dir + "/quickshell/shared/pam"
        config: "password.conf"
        user: root.user
        onPamMessage: if (responseRequired) respond(root.password)
        onCompleted: result => {
            root.checking = false
            if (result === PamResult.Success) {
                root.menuOpen = false
                root.leave()
            } else {
                root.password = ""
                root.failed = true
                root.rejected()
            }
        }
        onError: { root.checking = false; root.password = ""; root.failed = true; root.rejected() }
    }

    property bool capsLock: false
    Process {
        id: capsProc
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.capsLock = JSON.parse(text).keyboards.some(k => k.main && k.capsLock) } catch (e) {}
            }
        }
    }
    function checkCaps() { if (!capsProc.running) capsProc.running = true }


    property bool idle: false
    function poke() {
        idle = false
        idleTimer.restart()
    }
    Timer {
        id: idleTimer
        interval: 12000
        running: true
        onTriggered: root.idle = root.cfg.idleHide && root.password === "" && !root.menuOpen
    }


    readonly property var player: MediaShared.pickPlayer("")
    NowPlayingShared { id: nowPlaying; player: root.player }
    MediaViewShared { on: root.t > 0 && root.cfg.music }
    readonly property alias track: nowPlaying

    readonly property bool charging: PowerShared.charging || PowerShared.full

    readonly property string mainScreen: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    property string lockedOn: ""
    onMainScreenChanged: if (lockedOn === "") lockedOn = mainScreen
    Component.onCompleted: { lockedOn = mainScreen; checkCaps() }
}
