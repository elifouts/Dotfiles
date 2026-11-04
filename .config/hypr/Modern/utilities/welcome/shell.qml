import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../common"

ShellRoot {
    id: root

    readonly property string flag: Hypr.home + "/.cache/dotfiles-welcome"
    readonly property string util: Hypr.util + "/"
    property var screen: Quickshell.screens[0]
    property int step: 0
    property int shown: 0
    property real fade: 1

    readonly property var steps: [
        { title: "Keybinds", keys: ["SUPER", "launcher / Keybinds", "SUPER Q", "terminal", "SUPER B", "close", "SUPER 1-9", "workspaces", "SUPER TAB", "overview"] },
        { title: "Settings", hint: "ALT S", where: "settings", pages: [
            ["profile", "Tweaks save as overrides or profiles."], ["colors", "Schemes, or from your wallpaper."],
            ["windows", "Gaps, borders, tiling."], ["effects", "Blur, shadows"], ["animations", "Speed and curves."],
            ["input", "Mouse, keyboard, cursor."], ["system", "Startup and display."]] },
        { title: "Waybar", hint: "ALT A", text: "Default bar. I made a quickshell one too.", where: "bar" },
        { title: "Profiles", hint: "SUPER P", text: "My saved looks. Save yours in settings.", where: "profiles", flip: true },
        { title: "Launcher", hint: "SUPER", text: "Apps, commands, keybinds.", where: "launcher" },
        { title: "Thanks", text: "Thanks for using my dotfiles.\n— Eli" }
    ]
    readonly property var cur: steps[shown]
    readonly property bool held: shown === 0 || shown === steps.length - 1
    property bool auto: true
    property real prog: 0
    property int sub: 0
    readonly property string words: cur.pages ? cur.pages[sub][1] : cur.text ?? ""

    function panel(name, call) {
        if (!name || name === "bar") return
        Quickshell.execDetached(["sh", "-c", (name === "settings" && call === "close" ? util + "session/shells.sh settings unflip; " : "") + util + "session/shells.sh " + name + " " + call])
    }

    function show() {
        const focused = Hypr.focusedScreen()
        screen = focused?.width >= focused?.height
            ? focused
            : Quickshell.screens.find(s => s.width >= s.height) ?? Quickshell.screens[0]   
        step = shown = 0
        front = 0
        fade = 1
        auto = true
        tick()
        Theme.refresh()
        morph.open()
    }
    function close() {
        clock.stop()
        idle.stop()
        panel(cur.where, "close")
        morph.close()
        Quickshell.execDetached(["rm", "-f", flag])
    }
    function go(d) {
        if (step + d < 0) return
        if (step + d >= steps.length) return close()
        step += d
        if (steps[step].where !== cur.where) panel(cur.where, "close")
        swap.restart()
    }
    function nudge(d) {
        auto = false
        idle.restart()
        tick()
        go(d)
    }
    function tick() {
        clock.stop()
        prog = 0
        if (auto && !held) clock.start()
    }
    function enter() {
        shown = step
        sub = 0
        tick()
    }
    function arrive() {
        panel(cur.where, "open")
        if (cur.pages) peek()
        if (cur.where && cur.where !== "bar") raise.restart()
        else raise.stop()
    }

    function peek() { Quickshell.execDetached([util + "session/shells.sh", "settings", "peek", cur.pages[sub][0]]) }

    NumberAnimation { id: clock; target: root; property: "prog"; from: 0; to: 1; duration: root.cur.pages ? root.cur.pages.length * 5000 : 7000; onFinished: if (root.prog >= 1) root.go(1) }
    Timer { id: idle; interval: 5000; onTriggered: { root.auto = true; root.tick() } }
    Timer {
        interval: root.cur.pages ? 5000 : 1300
        repeat: true
        running: morph.active && (!!root.cur.flip || !!root.cur.pages) && root.fade === 1
        onTriggered: {
            if (!root.cur.pages) return Quickshell.execDetached([root.util + "session/shells.sh", "profiles", "flip"])
            root.sub = (root.sub + 1) % root.cur.pages.length
            root.peek()
        }
    }

    function spot(w, h) {
        const W = screen.width, H = screen.height, gap = 32
        const lw = Math.round((4 * 70 + 3 * 26 + 36) * Hypr.scaleFor(screen)) + 24
        switch (cur.where) {
        case "settings": return Qt.point(W / 3 + gap, (H - h) / 2)
        case "bar": return Qt.point((W - w) / 2, 64)
        case "profiles": return Qt.point(W - 250 - gap - w, (H - h) / 2)
        case "launcher": return Qt.point((W + lw) / 2 + gap, H - h - 40)
        default: return Qt.point((W - w) / 2, (H - h) / 2)
        }
    }

    Morph { id: morph }

    SequentialAnimation {
        id: swap
        NumberAnimation { target: root; property: "fade"; to: 0; duration: Theme.ms(140); easing.type: Easing.OutCubic }
        ScriptAction { script: root.enter() }
        PauseAnimation { duration: Theme.ms(440) }
        ScriptAction { script: root.arrive() }
        Settle { target: root; property: "fade"; to: 1; duration: Theme.ms(240) }
    }

    readonly property real tw: (front ? b1 : b0).bodyW + 44
    readonly property real th: (front ? b1 : b0).bodyH + 40
    readonly property bool glide: morph.t > 0.98 && !morph.leaving
    property rect box: { const p = spot(tw, th); return Qt.rect(p.x, p.y, tw, th) }
    Behavior on box { enabled: root.glide; PropertyAnimation { duration: Theme.ms(440); easing.type: Easing.InOutCubic } }

    property int front: 0
    property bool swapping: false
    SequentialAnimation {
        id: raise
        PauseAnimation { duration: 280 }
        PropertyAction { target: root; property: "swapping"; value: true }
        PauseAnimation { duration: 50 }
        ScriptAction { script: root.front = 1 - root.front }
        PauseAnimation { duration: 50 }
        PropertyAction { target: root; property: "swapping"; value: false }
    }

    FileView {
        path: root.flag
        printErrors: false
        onLoaded: bootDelay.start()
    }
    Timer { id: bootDelay; interval: 5000; onTriggered: root.show() }

    IpcHandler {
        target: "welcome"
        function open(): void { root.show() }
        function close(): void { root.close() }
        function next(): void { root.go(1) }
        function back(): void { root.go(-1) }
    }

    component Blob: PanelWindow {
        id: win
        required property int slot
        readonly property real bodyW: body.implicitWidth
        readonly property real bodyH: body.implicitHeight
        readonly property bool on: root.front === slot
        visible: morph.active && (on || root.swapping)
        screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "welcome"
        WlrLayershell.keyboardFocus: on && morph.active && !morph.leaving ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Item {
            id: blob
            readonly property real dot: 52
            width: Math.round(dot + (root.box.width - dot) * Math.min(1, morph.mw))
            height: Math.round(dot + (root.box.height - dot) * Math.min(1, morph.mh))
            x: Math.round(root.box.x + (root.box.width - width) / 2)
            y: Math.round(root.box.y + (root.box.height - height) / 2 + (1 - morph.rise) * 24)
            opacity: win.on ? Math.min(1, morph.t * 8) : 0
            clip: true
            focus: win.on

            Keys.onPressed: e => {
                if (e.key === Qt.Key_Right || e.key === Qt.Key_L || e.key === Qt.Key_Return) root.nudge(1)
                else if (e.key === Qt.Key_Left || e.key === Qt.Key_H) root.nudge(-1)
            }

            Rectangle {
                anchors.fill: parent
                radius: Math.min(parent.height / 2, Theme.r(18))
                color: Theme.panel
                border.width: 1
                border.color: Theme.edge
            }

            Column {
                id: body
                x: 22
                y: 20
                spacing: 12
                opacity: morph.stage(0.55) * root.fade

                Row {
                    id: top
                    spacing: 10
                    Label { id: head; text: root.cur.title; font.pixelSize: 18; color: Theme.accent }
                    Label { visible: !!root.cur.hint; anchors.baseline: head.baseline; text: root.cur.hint ?? ""; font.pixelSize: 11; color: Theme.dim }
                }

                Label {
                    id: words
                    visible: text !== ""
                    text: root.words
                    font.pixelSize: 12
                    color: Theme.fg
                    lineHeight: 1.2
                    onTextChanged: textIn.restart()
                    NumberAnimation { id: textIn; target: words; property: "opacity"; from: 0; to: 1; duration: Theme.ms(260); easing.type: Easing.OutCubic }
                }

                Grid {
                    id: keys
                    visible: !!root.cur.keys
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 8
                    Repeater {
                        model: root.cur.keys ?? []
                        Label { required property string modelData; required property int index; text: modelData; font.pixelSize: 12; color: index % 2 ? Theme.dim : Theme.accent }
                    }
                }

                Item {
                    width: Math.max(root.shown ? 180 : 240, top.implicitWidth, words.implicitWidth, keys.implicitWidth)
                    height: 22

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5
                        Repeater {
                            model: root.steps.length
                            Rectangle {
                                required property int index
                                readonly property bool on: index === root.step
                                width: on ? 22 : 5
                                height: 5
                                radius: 2.5
                                color: Theme.alpha(Theme.fg, 0.2)
                                Behavior on width { Settle { duration: Theme.move } }
                                Rectangle {
                                    width: parent.on ? Math.max(5, parent.width * (root.held ? 1 : root.prog)) : 0
                                    height: parent.height
                                    radius: parent.radius
                                    color: Theme.accent
                                }
                            }
                        }
                    }

                    Row {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: 14
                        IconButton { visible: root.shown === 0; text: "been here"; font.pixelSize: 11; onClicked: root.nudge(root.steps.length - 1 - root.step) }
                        IconButton { visible: root.step === root.steps.length - 1; text: "restart"; font.pixelSize: 11; onClicked: root.nudge(-root.step) }
                        IconButton { text: ""; font.pixelSize: 13; opacity: root.step ? 1 : 0.3; onClicked: root.nudge(-1) }
                        IconButton { text: root.step === root.steps.length - 1 ? "" : ""; font.pixelSize: 13; idle: Theme.accent; hot: Theme.bright; onClicked: root.nudge(1) }
                    }
                }
            }
        }
    }

    Blob { id: b0; slot: 0 }
    Blob { id: b1; slot: 1 }
}
