import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../../shared"
import "../common"

ShellRoot {
    id: root

    readonly property string py: HyprShared.util + "/settings/hypr-settings.py"
    property var entries: []
    property string live: ""
    readonly property int n: entries.length
    property int cur: 0
    property real pos: 0
    readonly property var picked: n ? entries[mod(cur)] : null
    property alias active: morph.active
    property alias leaving: morph.leaving
    property alias t: morph.t
    property real p: 1
    property real scrollAcc: 0
    property var targetScreen: null

    readonly property real dot: 52
    readonly property real fan: morph.stage(0.5)
    MorphShared { id: morph; sideways: true }

    function mod(i) { return n ? ((i % n) + n) % n : 0 }
    function wrap(x) { return n ? mod(x + n / 2) - n / 2 : 0 }

    onCurChanged: { settle.stop(); settle.to = cur; settle.start(); p = 1; play.restart() }
    SettleShared { id: settle; target: root; property: "pos"; duration: Theme.ms(420) }

    function show() {
        if (active && !leaving) return
        Theme.refresh()
        list.running = true
        HyprShared.locate(s => {
            targetScreen = s
            morph.open()
            warp.restart()
        })
    }

    function close() { morph.close() }

    function apply() {
        if (picked && picked.id !== live) Quickshell.execDetached(["python3", py, "saved", "apply", picked.id])
        close()
    }

    SequentialAnimation {
        id: play
        loops: Animation.Infinite
        running: root.active
        NumberAnimation { target: root; property: "p"; to: 0; duration: Theme.ms(220); easing.type: Easing.InOutQuad }
        PauseAnimation { duration: 250 }
        NumberAnimation {
            target: root
            property: "p"
            to: 1
            duration: root.picked ? root.picked.ms : 300
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.picked ? root.picked.curve.concat([1, 1]) : [0.15, 0.85, 0.25, 1, 1, 1]
        }
        PauseAnimation { duration: 1400 }
    }

    Process {
        id: list
        command: ["python3", root.py, "saved", "preview"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text)
                    root.live = d.active
                    root.entries = d.entries
                    root.cur = Math.max(0, d.entries.findIndex(e => e.id === d.active))
                    root.pos = root.cur
                } catch (e) {}
            }
        }
    }

    Timer {
        id: warp
        interval: 30
        onTriggered: {
            const s = root.targetScreen
            if (!s) return
            const x = Math.round(s.x + s.width - content.width / 2)
            const y = Math.round(s.y + s.height / 2)
            HyprShared.dispatch("hl.dsp.cursor.move({ x = " + x + ", y = " + y + " })", "movecursor " + x + " " + y)
        }
    }

    IpcHandler {
        target: "profiles"
        function toggle(): void { root.active && !root.leaving ? root.close() : root.show() }
        function open(): void { root.show() }
        function close(): void { root.close() }
        function flip(): void { root.cur++ }
    }

    PanelWindow {
        visible: root.active
        screen: root.targetScreen ?? Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "profile-switcher"
        WlrLayershell.keyboardFocus: root.active && !root.leaving ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Item {
            id: card
            width: root.dot + (content.width - root.dot) * morph.mw
            height: root.dot + (content.height - root.dot) * morph.mh
            readonly property real rest: Math.min(root.dot / 2, Theme.rounding)
            readonly property real radius: Math.max(rest, root.dot / 2 - (root.dot / 2 - rest) * Math.min(1, morph.mh))
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.active ? Math.min(1, root.t * 8) : 0
            transform: Translate { x: (1 - morph.rise) * (root.dot + 24) }
            clip: true
            focus: true

            Rectangle {
                width: parent.width + card.radius + 2
                height: parent.height
                radius: card.radius
                color: Theme.panel
                border.width: 1
                border.color: Theme.edge
            }

            Keys.onPressed: event => {
                const k = event.key
                if (k === Qt.Key_Tab || k === Qt.Key_Down || k === Qt.Key_J) root.cur++
                else if (k === Qt.Key_Backtab || k === Qt.Key_Up || k === Qt.Key_K) root.cur--
                else if (k === Qt.Key_Return || k === Qt.Key_Enter) root.apply()
                else if (k === Qt.Key_Escape) root.close()
                else return
                event.accepted = true
            }

            Item {
                id: content
                width: 250
                height: 450
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                opacity: morph.stage(0.55)

                MouseArea {
                    anchors.fill: parent
                    onWheel: wheel => {
                        root.scrollAcc += wheel.angleDelta.y
                        while (Math.abs(root.scrollAcc) >= 120) {
                            root.cur += root.scrollAcc > 0 ? -1 : 1
                            root.scrollAcc -= root.scrollAcc > 0 ? 120 : -120
                        }
                    }
                }

                Column {
                    x: 16
                    y: 14
                    spacing: 2
                    opacity: 1 - 0.7 * Math.min(1, Math.abs(root.pos - root.cur))
                    LabelShared {
                        text: root.picked ? root.picked.name : ""
                        font.pixelSize: 15
                        color: root.picked && root.picked.id === root.live ? Theme.accent : Theme.bright
                    }
                    LabelShared {
                        text: root.picked ? root.picked.bar : ""
                        font.pixelSize: 11
                        color: Theme.dim
                    }
                }

                ClippingRectangle {
                    id: strip
                    readonly property var ramp: (root.picked ? root.picked.colors : []).slice().sort((x, y) => {
                        const l = c => { c = Qt.color(c); return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
                        return l(x) - l(y)
                    })
                    x: parent.width - width - 8
                    y: 14
                    z: 1
                    width: 5
                    height: parent.height - 28
                    radius: 2.5
                    color: "transparent"
                    opacity: root.fan

                    Column {
                        Repeater {
                            model: 16
                            Rectangle {
                                required property int index
                                width: strip.width
                                height: strip.height / 16
                                color: strip.ramp[index] ?? "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.ms(420); easing.type: Easing.InOutSine } }
                            }
                        }
                    }
                }

                Item {
                    id: wheel
                    anchors.fill: parent
                    anchors.topMargin: 56

                    Repeater {
                        model: root.entries

                        Item {
                            id: env
                            required property var modelData
                            required property int index
                            readonly property real d: root.wrap(index - root.pos)
                            readonly property real ad: Math.abs(d)
                            readonly property bool centered: root.mod(root.cur) === index
                            property real wp: 1
                            Binding on wp { when: env.centered; value: root.p; restoreMode: Binding.RestoreNone }
                            onCenteredChanged: if (!centered) reopen.start()
                            NumberAnimation { id: reopen; target: env; property: "wp"; to: 1; duration: Theme.ms(260); easing.type: Easing.OutCubic }

                            visible: ad < 2.5
                            width: 210
                            height: 112
                            x: (wheel.width - width) / 2
                            y: (wheel.height - height) / 2 + d * 136 * root.fan
                            z: -ad
                            scale: 1 - 0.16 * Math.min(ad, 2)
                            opacity: Math.max(0, 1 - 0.45 * ad) * root.fan
                            transform: Rotation {
                                origin.x: env.width / 2
                                origin.y: env.height / 2
                                axis { x: 1; y: 0; z: 0 }
                                angle: -env.d * 32
                            }

                            ClippingRectangle {
                                id: shot
                                width: parent.width
                                height: 112
                                radius: Theme.r(10)
                                color: env.modelData.colors[0] ?? Theme.bg

                                Image {
                                    id: wall
                                    anchors.fill: parent
                                    source: env.modelData.thumb ? "file://" + env.modelData.thumb : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }

                                Item {
                                    id: box
                                    readonly property string style: env.modelData.style
                                    readonly property real from: { const m = /(\d+)%/.exec(style); return m ? m[1] / 100 : 0.8 }
                                    width: parent.width * 0.56
                                    height: parent.height * 0.56
                                    anchors.centerIn: parent
                                    opacity: Math.min(1, env.wp * 2)
                                    scale: style.startsWith("popin") ? from + (1 - from) * env.wp : 1
                                    transform: [
                                        Scale { origin.y: box.height / 2; yScale: box.style.startsWith("gnomed") ? env.wp : 1 },
                                        Translate { x: box.style.startsWith("slide") ? (1 - env.wp) * 120 : 0 }
                                    ]

                                    ClippingRectangle {
                                        anchors.fill: parent
                                        radius: env.modelData.rounding / 2
                                        color: "transparent"

                                        MultiEffect {
                                            visible: env.modelData.blur
                                            x: -box.x
                                            y: -box.y
                                            width: shot.width
                                            height: shot.height
                                            source: wall
                                            blurEnabled: true
                                            blur: 1
                                            blurMax: 48
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: env.modelData.rounding / 2
                                        color: Theme.alpha(Qt.color(env.modelData.colors[0] ?? "#000000"), env.modelData.opacity * 0.75)
                                        border.width: Math.min(2, env.modelData.border)
                                        border.color: env.modelData.colors[9] ?? Theme.accent
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: Theme.back(0.5 * Math.min(1, env.ad))
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: env.centered ? root.apply() : root.cur += Math.round(env.d)
                            }
                        }
                    }
                }
            }
        }
    }
}
