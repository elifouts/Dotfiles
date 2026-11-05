import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick.Controls
import "../common"
import QtQuick.Shapes

Scope {
    id: scan

    component Plate: Shape {
        id: plate
        property real cut: 10
        property real fill: 0.82
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: 1
            strokeColor: Theme.alpha(Theme.accent, 0.35)
            fillColor: Theme.alpha(Theme.bg, plate.fill)
            startX: plate.cut; startY: 0
            PathLine { x: plate.width; y: 0 }
            PathLine { x: plate.width; y: plate.height }
            PathLine { x: 0; y: plate.height }
            PathLine { x: 0; y: plate.cut }
            PathLine { x: plate.cut; y: 0 }
        }
    }

    signal done()
    property real t: 0
    property var s: ({})
    property var last: [0, 0]
    property real cpu: 0

    Component.onCompleted: { poll.running = true; opening.start() }
    NumberAnimation { id: opening; target: scan; property: "t"; to: 1; duration: Theme.slow; easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: closing
        NumberAnimation { target: scan; property: "t"; to: 0; duration: Theme.quick; easing.type: Easing.InCubic }
        ScriptAction { script: scan.done() }
    }
    function close() { if (!closing.running) { opening.stop(); closing.start() } }
    function stage(i) { return Math.max(0, Math.min(1, (t - i * 0.07) / (1 - i * 0.07))) }

    Timer { interval: 1500; running: true; repeat: true; onTriggered: poll.running = true }
    Process {
        id: poll
        command: [Quickshell.shellPath("scan/stats.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {}
                for (const l of text.split("\n")) {
                    const i = l.indexOf(" ")
                    if (l.startsWith("cpu ")) {
                        const n = l.trim().split(/\s+/).slice(1).map(Number), tot = n.reduce((a, b) => a + b, 0), idle = n[3] + n[4]
                        if (scan.last[0]) scan.cpu = 1 - (idle - scan.last[1]) / Math.max(1, tot - scan.last[0])
                        scan.last = [tot, idle]
                    } else if (l.includes(":")) o[l.split(":")[0]] = parseInt(l.split(":")[1])
                    else if (i > 0) o[l.slice(0, i)] = l.slice(i + 1)
                }
                scan.s = o
            }
        }
    }
    readonly property real ram: s.MemTotal ? 1 - s.MemAvailable / s.MemTotal : 0
    readonly property var gpu: (s.GPU || "").split(",").map(x => x.trim())
    function gb(used, total, div) { return (used / div).toFixed(1) + " / " + (total / div).toFixed(1) + " GB" }
    function uptime(sec) {
        const d = Math.floor(sec / 86400), h = Math.floor(sec % 86400 / 3600), m = Math.floor(sec % 3600 / 60)
        return (d ? d + "d " : "") + h + "h " + m + "m"
    }

    component Block: Item {
        id: block
        property int order: 0
        property int side: -1
        property string glyph
        property string title
        default property alias content: col.data
        readonly property real k: scan.stage(order)
        width: 330
        height: col.height + 46
        opacity: k
        transform: Translate { x: block.side * 50 * (1 - block.k) }
        Plate { anchors.fill: parent; fill: 0.55; cut: 14 }
        Rectangle { x: block.side < 0 ? 0 : parent.width - 2; y: 14; width: 2; height: parent.height - 14; color: Theme.accent }
        Kit.Title { x: 16; y: 10; width: parent.width - 32; glyph: block.glyph; text: block.title }
        Column { id: col; x: 16; y: 40; width: parent.width - 32; spacing: 5 }
    }
    component Read: Item {
        property string k
        property string v
        width: parent.width
        height: 17
        Hud { text: parent.k; height: parent.height; color: Theme.alpha(Theme.fg, 0.45) }
        Hud {
            caps: false
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 90
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft
            text: parent.v
            font.pixelSize: 12
            color: Theme.fg
        }
    }
    component Meter: Kit.Slide {
        property real target: 0
        value: target
        Behavior on value { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property var modelData
            readonly property bool main: modelData === Ui.target
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.alpha(Theme.void_, 0.3 * scan.t)
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "space-scan"
            WlrLayershell.keyboardFocus: main ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            MouseArea { z: -1; anchors.fill: parent; onClicked: scan.close() }
            Item { focus: win.main; Keys.onPressed: scan.close() }

            Repeater {
                model: win.main ? 4 : 0
                Item {
                    required property int index
                    readonly property bool r: index % 2 === 1
                    readonly property bool b: index > 1
                    readonly property real in_: 40 + 60 * (1 - scan.t)
                    x: r ? win.width - in_ - 40 : in_
                    y: b ? win.height - in_ - 40 : in_
                    width: 40
                    height: 40
                    opacity: scan.t
                    Rectangle { width: 40; height: 2; y: parent.b ? 38 : 0; color: Theme.accent }
                    Rectangle { width: 2; height: 40; x: parent.r ? 38 : 0; color: Theme.accent }
                }
            }

            Item {
                anchors.fill: parent
                visible: win.main

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 90
                    opacity: scan.t
                    spacing: 2
                    SystemClock { id: clock; precision: SystemClock.Seconds }
                    Hud {
                        caps: false
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(clock.date, Store.values["space.clock24"] === false ? "h:mm:ss" : "HH:mm:ss")
                        font.pixelSize: 34
                        font.weight: Font.ExtraLight
                        font.letterSpacing: 4
                        color: Theme.fg
                    }
                    Hud {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(clock.date, "dddd · dd MMMM") + "  ·  " + Hyprland.toplevels.values.length + " windows  ·  up " + scan.uptime(parseFloat(scan.s.UP || 0))
                    }
                }

                Column {
                    x: 110
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14
                    Block {
                        order: 0; glyph: "󰒋"; title: scan.s.HOST || "system"
                        Read { k: "os"; v: scan.s.OS || "" }
                        Read { k: "kernel"; v: scan.s.KERN || "" }
                        Read { k: "user"; v: Quickshell.env("USER") }
                    }
                    Block {
                        order: 1; glyph: "󰍛"; title: "processor"
                        Read { k: "model"; v: scan.s.CPUM || "" }
                        Meter { glyph: "󰓅"; target: scan.cpu }
                        Read { visible: !!scan.s.CPUT; k: "temp"; v: Math.round((scan.s.CPUT || 0) / 1000) + "°" }
                    }
                    Block {
                        order: 2; glyph: "󰘚"; title: "memory"
                        Meter { glyph: "󰍛"; target: scan.ram }
                        Read { k: "used"; v: scan.gb(scan.s.MemTotal - scan.s.MemAvailable, scan.s.MemTotal, 1048576) }
                    }
                }

                Column {
                    anchors.right: parent.right
                    anchors.rightMargin: 110
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14
                    Block {
                        visible: !!scan.s.GPU
                        side: 1; order: 0; glyph: "󰢮"; title: "graphics"
                        Read { k: "card"; v: scan.gpu[0] || "" }
                        Meter { glyph: "󰓅"; target: (parseFloat(scan.gpu[1]) || 0) / 100 }
                        Read { k: "vram"; v: scan.gb(parseFloat(scan.gpu[2]) || 0, parseFloat(scan.gpu[3]) || 0, 1024) }
                        Read { k: "temp"; v: (scan.gpu[4] || "") + "°" }
                    }
                    Block {
                        side: 1; order: 1; glyph: "󰤨"; title: "link"
                        Read { k: "network"; v: Sys.net }

                        Kit.Slide {
                            glyph: Audio.muted ? "󰝟" : Audio.volume <= 0.5 ? "󰖀" : "󰕾"
                            value: Audio.volume

                            onMoved: v => Audio.setVolume(v)
                        }

                        Meter {
                            glyph: Power.charging ? "󰂄" : "󰁹"
                            visible: Power.hasBattery
                            target: Power.charge
                        }
                    }
                    Block {
                        visible: !!Media.pickPlayer("")
                        side: 1; order: 2; glyph: "󰎈"; title: "now playing"
                        MediaCtl { width: parent.width }
                    }
                }
            }
        }
    }
}
