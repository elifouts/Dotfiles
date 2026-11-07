import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../style/common"

Scope {
    id: root

    property var steps: []
    property var spots: ({})
    signal panel(string name, string call)
    signal peek(string page)

    readonly property string flag: HyprShared.home + "/.cache/dotfiles-welcome"
    readonly property bool active: morph.active
    property var screen: Quickshell.screens[0]
    property int step: 0
    property int shown: 0
    property real fade: 1
    property int replay: 0

    readonly property var cur: steps[shown]
    readonly property bool held: shown === 0 || shown === steps.length - 1
    property bool auto: true
    property real prog: 0
    property int sub: 0
    readonly property string words: cur.pages ? cur.pages[sub][1] : cur.text ?? ""

    function drive(call) {
        if (cur.where && cur.where !== "bar") panel(cur.where, call)
    }

    function show() {
        const focused = HyprShared.focusedScreen()
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
        drive("close")
        morph.close()
        Quickshell.execDetached(["rm", "-f", flag])
    }
    function go(d) {
        if (step + d < 0) return
        if (step + d >= steps.length) return close()
        step += d
        if (steps[step].where !== cur.where) drive("close")
        reveal.stop()
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
        drive("open")
        if (cur.pages) peek(cur.pages[sub][0])
        if (cur.where && cur.where !== "bar") raise.restart()
        else {
            raise.stop()
            reveal.restart()
        }
    }

    NumberAnimation { id: clock; target: root; property: "prog"; from: 0; to: 1; duration: root.cur.ms ?? (root.cur.pages ? root.cur.pages.length * (root.cur.beat ?? 5000) : 7000); onFinished: if (root.prog >= 1) root.go(1) }
    Timer { id: idle; interval: 5000; onTriggered: { root.auto = true; root.tick() } }
    Timer {
        interval: root.cur.beat ?? 5000
        repeat: true
        running: morph.active && !!root.cur.pages && root.fade === 1
        onTriggered: {
            root.sub = (root.sub + 1) % root.cur.pages.length
            root.peek(root.cur.pages[root.sub][0])
        }
    }

    MorphShared { id: morph }

    SequentialAnimation {
        id: swap
        NumberAnimation { target: root; property: "fade"; to: 0; duration: Theme.ms(220); easing.type: Easing.OutCubic }
        ScriptAction { script: root.enter() }
        PauseAnimation { duration: Theme.ms(440) }
        ScriptAction { script: root.arrive() }
    }
    SequentialAnimation {
        id: reveal
        ScriptAction { script: root.replay++ }
        SettleShared { target: root; property: "fade"; to: 1; duration: Theme.ms(240) }
    }

    readonly property real tw: (front ? b1 : b0).bodyW + 44
    readonly property real th: (front ? b1 : b0).bodyH + 40
    readonly property bool glide: morph.t > 0.98 && !morph.leaving
    property rect box: {
        const W = screen.width, H = screen.height, spot = spots[cur.where]
        const p = spot ? spot(W, H, tw, th) : Qt.point((W - tw) / 2, (H - th) / 2)
        return Qt.rect(p.x, p.y, tw, th)
    }
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
        ScriptAction { script: if (!swap.running) reveal.restart() }
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
            readonly property real w: dot + (root.box.width - dot) * Math.min(1, morph.mw)
            readonly property real h: dot + (root.box.height - dot) * Math.min(1, morph.mh)
            readonly property real cx: root.box.x + root.box.width / 2
            readonly property real cy: root.box.y + root.box.height / 2 + (1 - morph.rise) * 24
            x: Math.round(cx - w / 2)
            y: Math.round(cy - h / 2)
            width: Math.round(cx + w / 2) - x
            height: Math.round(cy + h / 2) - y
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
            Rectangle { width: parent.width; height: Theme.lines * 2; color: Theme.accent }

            Column {
                id: body
                x: 22
                y: 20
                spacing: 12
                opacity: morph.stage(0.55) * root.fade

                Row {
                    id: top
                    spacing: 10
                    Say { id: head; replay: root.replay; text: root.cur.title; font.pixelSize: 18; font.capitalization: Theme.caps; font.letterSpacing: Theme.tracking; color: Theme.accent }
                    Say { replay: root.replay; visible: !!root.cur.hint; anchors.baseline: head.baseline; text: root.cur.hint ?? ""; font.pixelSize: 11; color: Theme.dim }
                }

                Say {
                    id: words
                    replay: root.replay
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
                        Say { required property string modelData; required property int index; replay: root.replay; text: modelData; font.pixelSize: 12; color: index % 2 ? Theme.dim : Theme.accent }
                    }
                }

                TextMetrics {
                    id: longest
                    font: words.font
                    text: (root.cur.pages ?? []).reduce((a, p) => p[1].length > a.length ? p[1] : a, "")
                }

                Item {
                    width: Math.max(top.implicitWidth, words.implicitWidth, keys.implicitWidth, longest.advanceWidth, dots.implicitWidth + 20 + buttons.implicitWidth)
                    height: 22

                    Row {
                        id: dots
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5
                        Repeater {
                            model: root.steps.length
                            Rectangle {
                                required property int index
                                readonly property bool on: index === root.step
                                width: on ? 22 : 5
                                height: 5
                                radius: 2.5 * Theme.round
                                color: Theme.alpha(Theme.fg, 0.2)
                                Behavior on width { SettleShared { duration: Theme.move } }
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
                        id: buttons
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: 14
                        IconButtonShared { visible: root.shown === 0; text: "been here"; font.pixelSize: 11; onClicked: root.nudge(root.steps.length - 1 - root.step) }
                        IconButtonShared { visible: root.shown === root.steps.length - 1; text: "restart"; font.pixelSize: 11; onClicked: root.nudge(-root.step) }
                        IconButtonShared { text: "\uf053"; font.pixelSize: 13; opacity: root.step ? 1 : 0.3; onClicked: root.nudge(-1) }
                        IconButtonShared { text: "\uf054"; font.pixelSize: 13; idle: Theme.accent; hot: Theme.bright; onClicked: root.nudge(1) }
                    }
                }
            }
        }
    }

    Blob { id: b0; slot: 0 }
    Blob { id: b1; slot: 1 }
}
