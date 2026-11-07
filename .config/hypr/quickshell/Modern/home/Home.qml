import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../../shared"
import "../music" as Music
import "../common"

Scope {
    id: root

    signal done()

    readonly property bool portrait: win.screen ? win.screen.height > win.screen.width : false
    readonly property real u: unitFor(win.screen)
    readonly property real rounding: Theme.rounding
    function rr(v) { return v * rounding / 10 * u }

    readonly property real sysW: portrait ? 352 : 330

    function unitFor(s) {
        if (!s) return 1
        const v = s.height > s.width
            ? Math.min(s.width / 760, s.height / 1350)
            : Math.min(s.width / 1600, s.height / 900)
        return Math.max(0.6, v)
    }

    property bool shown: false
    property bool closing: false
    property real t: 0
    property var walls: ({})
    property var targetScreen: null
    property bool wallReady: false
    property string pendingCmd: ""
    property bool startWaited: false
    readonly property color glass: Theme.back(0.5)

    property real cpu: 0
    property real prevTotal: 0
    property real prevIdle: 0
    property real memTotal: 1
    property real memAvail: 1
    property real uptime: 0
    property string kernel: ""
    property string host: ""
    property string os: ""
    property string cpuModel: ""
    property real cpuTemp: 0
    property bool hasBattery: false
    property int batPct: 0
    property string batState: ""
    property bool hasGpu: false
    property string gpuName: ""
    property real gpuUtil: 0
    property real gpuMemUsed: 0
    property real gpuMemTotal: 1
    property real gpuTemp: 0

    readonly property bool dnd: NotifsShared.dnd
    readonly property var notifs: NotifsShared.notifs
    readonly property int notifCount: NotifsShared.count
    Binding { target: NotifsShared; property: "quiet"; value: root.shown }

    property int calY: new Date().getFullYear()
    property int calM: new Date().getMonth()
    readonly property var cells: {
        const first = new Date(calY, calM, 1)
        const offset = (first.getDay() + 6) % 7
        const days = new Date(calY, calM + 1, 0).getDate()
        const out = []
        for (let i = 0; i < 42; i++) {
            const d = i - offset + 1
            out.push(d >= 1 && d <= days ? d : 0)
        }
        return out
    }

    readonly property var player: {
        const list = MediaShared.players
        return list.find(p => p.isPlaying) ?? list[0] ?? null
    }
    NowPlayingShared { id: track; player: root.player }
    MediaViewShared { on: root.shown && !root.closing }

    function animateTo(target) {
        tween.stop()
        tween.from = t
        tween.to = target
        tween.duration = Theme.ms(target === 1 ? 1200 : 450)
        tween.easing.type = target === 1 ? Easing.OutCubic : Easing.InOutCubic
        tween.start()
    }

    function tryStart() {
        if (shown && !closing && (wallReady || startWaited)) animateTo(1)
    }

    function wallFor(name) {
        return walls[name] ?? walls["*"] ?? ""
    }

    function show() {
        Theme.refresh()
        startTimer.stop()
        watchdog.stop()
        closing = false
        if (shown) {
            animateTo(1)
            return
        }
        if (locating) return
        locating = true
        HyprShared.locate(open)
    }

    property bool locating: false
    function open(screen) {
        locating = false
        if (shown) return
        t = 0
        NotifsShared.popups = []
        const now = new Date()
        calY = now.getFullYear()
        calM = now.getMonth()
        targetScreen = screen
        shown = true
        wallReady = false
        startWaited = false
        walPath.running = true
        stats.running = true
        startTimer.restart()
        waitTimer.restart()
        Qt.callLater(() => stage.forceActiveFocus())
    }

    function close() {
        if (!shown || closing) return
        closing = true
        startTimer.stop()
        waitTimer.stop()
        watchdog.restart()
        if (t < 0.001) finish()
        else animateTo(0)
    }

    function toggle() {
        if (shown && !closing) close()
        else show()
    }

    function finish() {
        watchdog.stop()
        startTimer.stop()
        waitTimer.stop()
        tween.stop()
        shown = false
        closing = false
        t = 0
        walls = ({})
        if (pendingCmd !== "") launchTimer.restart()
        else done()
    }

    Timer {
        id: launchTimer
        interval: 120
        onTriggered: {
            const c = root.pendingCmd
            root.pendingCmd = ""
            if (c !== "") HyprShared.run(c)
            root.done()
        }
    }

    function run(cmd) {
        pendingCmd = cmd
        close()
    }

    function clearAll() { NotifsShared.clearAll() }

    function fmtUptime(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        return (d > 0 ? d + "d " : "") + h + "h " + m + "m"
    }

    function shiftMonth(step) {
        const d = new Date(calY, calM + step, 1)
        calY = d.getFullYear()
        calM = d.getMonth()
        monthFlip.restart()
    }

    function parseStats(text) {
        for (const l of text.split("\n")) {
            if (l.startsWith("cpu ")) {
                const f = l.trim().split(/\s+/).slice(1).map(Number)
                const idle = f[3] + f[4]
                const total = f.reduce((a, b) => a + b, 0)
                if (prevTotal > 0 && total > prevTotal) cpu = 1 - (idle - prevIdle) / (total - prevTotal)
                prevTotal = total
                prevIdle = idle
            } else if (l.startsWith("MemTotal:")) memTotal = parseInt(l.split(/\s+/)[1])
            else if (l.startsWith("MemAvailable:")) memAvail = parseInt(l.split(/\s+/)[1])
            else if (l.startsWith("UP ")) uptime = parseFloat(l.slice(3))
            else if (l.startsWith("KERN ")) kernel = l.slice(5)
            else if (l.startsWith("HOST ")) host = l.slice(5)
            else if (l.startsWith("OS ")) os = l.slice(3)
            else if (l.startsWith("CPUM ")) cpuModel = l.slice(5).replace(/\(R\)|\(TM\)|CPU /g, "").replace(/\s+/g, " ")
            else if (l.startsWith("CPUT ")) cpuTemp = parseInt(l.slice(5)) / 1000
            else if (l.startsWith("BAT ")) {
                const p = l.slice(4).split("|")
                hasBattery = true
                batPct = parseInt(p[0])
                batState = p[1]
            } else if (l.startsWith("GPU ")) {
                const p = l.slice(4).split(",").map(s => s.trim())
                hasGpu = true
                gpuName = p[0].replace("NVIDIA GeForce ", "")
                gpuUtil = parseFloat(p[1]) / 100
                gpuMemUsed = parseFloat(p[2])
                gpuMemTotal = parseFloat(p[3])
                gpuTemp = parseFloat(p[4])
            }
        }
    }

    NumberAnimation { id: tween; target: root; property: "t"; onFinished: if (root.closing) root.finish() }
    Timer { id: startTimer; interval: 30; onTriggered: root.tryStart() }
    Timer { id: waitTimer; interval: 450; onTriggered: { root.startWaited = true; root.tryStart() } }
    Timer { id: watchdog; interval: Theme.ms(1200) + 100; onTriggered: if (root.closing) root.finish() }

    SystemClock { id: clock; precision: SystemClock.Minutes; enabled: root.shown }

    Process {
        id: walPath
        command: [Quickshell.shellPath("style/home/home-wall.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.shown) return
                const m = {}
                for (const line of text.split("\n")) {
                    const i = line.indexOf("\t")
                    if (i > 0) m[line.slice(0, i)] = "file://" + encodeURI(line.slice(i + 1).trim())
                }
                root.walls = m
            }
        }
    }

    Process {
        id: stats
        command: [Quickshell.shellPath("shared/stats.sh")]
        stdout: StdioCollector { onStreamFinished: root.parseStats(text) }
    }
    Timer {
        interval: 2000
        running: root.shown
        repeat: true
        onTriggered: if (!stats.running) stats.running = true
    }


    component Glass: Item {
        id: g
        property string title: ""
        property real delay: 0
        default property alias content: body.data
        readonly property real p: Theme.seg(root.t, delay)

        opacity: p
        scale: 0.94 + 0.06 * p
        transform: Translate { y: (1 - g.p) * 44 * root.u }

        Rectangle {
            anchors.fill: parent
            radius: root.rounding
            color: root.glass
        }

        LabelShared {
            x: 24 * root.u
            y: 18 * root.u
            text: g.title
            font.pixelSize: 13 * root.u
            color: Theme.alpha(Theme.bright, 0.5)
        }

        Item {
            id: body
            anchors.fill: parent
            anchors.margins: 24 * root.u
            anchors.topMargin: 48 * root.u
        }
    }

    component RoundIcon: Item {
        id: ib
        property string glyph: ""
        property color tint: Theme.bright
        property real size: 40 * root.u
        signal clicked()
        width: size
        height: size
        scale: ima.pressed ? 0.85 : (ima.containsMouse ? 1.12 : 1)
        Behavior on scale { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutBack } }
        LabelShared {
            anchors.centerIn: parent
            text: ib.glyph
            font.pixelSize: ib.size * 0.5
            color: ib.tint
        }
        MouseArea { id: ima; anchors.fill: parent; hoverEnabled: true; onClicked: ib.clicked() }
    }

    component Gauge: Item {
        id: ga
        property real ratio: 0
        property string label: ""
        property string valueText: ""
        property color tint: Theme.accent
        property real shown: ratio
        Behavior on shown { NumberAnimation { duration: Theme.ms(700); easing.type: Easing.OutCubic } }

        width: 66 * root.u
        height: 92 * root.u

        Item {
            id: dial
            width: 66 * root.u
            height: 66 * root.u
            Shape {
                anchors.fill: parent
                layer.enabled: true
                layer.samples: 4
                ShapePath {
                    strokeColor: Theme.alpha(Theme.bright, 0.12)
                    strokeWidth: 6 * root.u
                    fillColor: "transparent"
                    PathAngleArc { centerX: dial.width / 2; centerY: dial.height / 2; radiusX: dial.width / 2 - 5 * root.u; radiusY: dial.height / 2 - 5 * root.u; startAngle: -90; sweepAngle: 360 }
                }
                ShapePath {
                    strokeColor: ga.tint
                    strokeWidth: 6 * root.u
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: dial.width / 2; centerY: dial.height / 2; radiusX: dial.width / 2 - 5 * root.u; radiusY: dial.height / 2 - 5 * root.u; startAngle: -90; sweepAngle: 359.9 * Math.max(0.001, Math.min(1, ga.shown)) }
                }
            }
            LabelShared {
                anchors.centerIn: parent
                text: ga.valueText
                font.pixelSize: 14 * root.u
                color: Theme.bright
            }
        }
        LabelShared {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 74 * root.u
            text: ga.label
            font.pixelSize: 12 * root.u
            color: Theme.alpha(Theme.bright, 0.6)
        }
    }

    component DockButton: Item {
        id: db
        property string glyph: ""
        property string label: ""
        property string cmd: ""
        width: 64 * root.u
        height: 64 * root.u
        scale: dma.pressed ? 0.9 : (dma.containsMouse ? 1.18 : 1)
        Behavior on scale { NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutBack } }

        Rectangle {
            anchors.fill: parent
            radius: root.rr(20)
            color: dma.containsMouse ? Theme.alpha(Theme.bright, 0.18) : Theme.alpha(Theme.bright, 0.08)
            Behavior on color { ColorAnimation { duration: Theme.ms(150) } }
        }
        LabelShared {
            anchors.centerIn: parent
            text: db.glyph
            font.pixelSize: 24 * root.u
            color: Theme.bright
        }
        LabelShared {
            anchors.horizontalCenter: parent.horizontalCenter
            y: -26 * root.u
            text: db.label
            opacity: dma.containsMouse ? 1 : 0
            font.pixelSize: 12 * root.u
            color: Theme.bright
            Behavior on opacity { NumberAnimation { duration: Theme.ms(150) } }
        }
        MouseArea { id: dma; anchors.fill: parent; hoverEnabled: true; onClicked: root.run(db.cmd) }
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: side
            required property var modelData
            readonly property real su: root.unitFor(modelData)

            screen: modelData
            visible: root.shown && modelData !== win.screen
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "home-screen"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Backdrop {
                anchors.fill: parent
                t: root.t
                source: root.wallFor(side.modelData.name)

                Column {
                    id: sideClock
                    readonly property real p: Theme.seg(root.t, 0.1)
                    anchors.centerIn: parent
                    opacity: p
                    transform: Translate { y: (1 - sideClock.p) * 16 * side.su }
                    spacing: 2 * side.su

                    LabelShared {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Theme.clock(clock.date)
                        font.pixelSize: 110 * side.su
                        font.weight: Font.Light
                        color: Theme.bright
                    }
                    LabelShared {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(clock.date, "dddd, d MMMM")
                        font.pixelSize: 20 * side.su
                        color: Theme.alpha(Theme.bright, 0.8)
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }
    }

    PanelWindow {
        id: win
        visible: root.shown
        screen: root.targetScreen ?? Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "home-screen"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Item {
            id: stage
            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                const k = event.key
                const pl = root.player
                if (k === Qt.Key_Escape) root.close()
                else if (k === Qt.Key_L) root.run(PowerShared.cmd("lock"))
                else if (k === Qt.Key_E) root.run(PowerShared.cmd("logout"))
                else if (k === Qt.Key_R) root.run(PowerShared.cmd("reboot"))
                else if (k === Qt.Key_S) root.run(PowerShared.cmd("poweroff"))
                else if (k === Qt.Key_Space && pl) MediaShared.toggle(pl)
                else if (k === Qt.Key_Right && pl) MediaShared.skip(pl, 1)
                else if (k === Qt.Key_Left && pl) MediaShared.skip(pl, -1)
                else if (k === Qt.Key_Up) AudioShared.setVolume(AudioShared.volume + 0.05)
                else if (k === Qt.Key_Down) AudioShared.setVolume(AudioShared.volume - 0.05)
                else if (k === Qt.Key_M) AudioShared.toggleMute()
                else if (k === Qt.Key_PageUp || k === Qt.Key_BracketLeft) root.shiftMonth(-1)
                else if (k === Qt.Key_PageDown || k === Qt.Key_BracketRight) root.shiftMonth(1)
                else if (k === Qt.Key_D) NotifsShared.dnd = !NotifsShared.dnd
                else if (k === Qt.Key_C) root.clearAll()
            }

            Backdrop {
                anchors.fill: parent
                t: root.t
                source: root.wallFor(win.screen ? win.screen.name : "")
                onStatusChanged: if (status === Image.Ready) { root.wallReady = true; startTimer.restart() }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            Column {
                id: clockBlock
                readonly property real p: Theme.seg(root.t, 0.02)
                anchors.horizontalCenter: parent.horizontalCenter
                y: 64 * root.u
                opacity: p
                transform: Translate { y: (1 - clockBlock.p) * -24 * root.u }
                spacing: 2 * root.u

                LabelShared {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Theme.clock(clock.date)
                    font.pixelSize: 128 * root.u
                    font.weight: Font.Light
                    color: Theme.bright
                }
                LabelShared {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(clock.date, "dddd, d MMMM")
                    font.pixelSize: 22 * root.u
                    color: Theme.alpha(Theme.bright, 0.8)
                }
            }

            Flow {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 330 * root.u
                width: (root.portrait ? 728 : 1424) * root.u
                spacing: 20 * root.u

                Glass {
                    id: media
                    width: 360 * root.u
                    height: 350 * root.u
                    title: "Now Playing"
                    delay: 0.06
                    readonly property var pl: root.player

                    Item {
                        anchors.right: parent.right
                        anchors.rightMargin: -6 * root.u
                        y: -35 * root.u
                        width: 28 * root.u
                        height: 28 * root.u
                        LabelShared {
                            anchors.centerIn: parent
                            text: "\uf1bc"
                            font.pixelSize: 20 * root.u
                            color: Theme.ok
                            opacity: spotifyMa.containsMouse ? 1 : 0.75
                            scale: spotifyMa.containsMouse ? 1.15 : 1
                            Behavior on opacity { NumberAnimation { duration: Theme.ms(120) } }
                            Behavior on scale { NumberAnimation { duration: Theme.ms(120) } }
                        }
                        HoverShared {
                            id: spotifyMa
                            anchors.fill: parent
                            onClicked: { root.close(); MediaShared.openSpotify() }
                        }
                    }

                    Column {
                        visible: !media.pl
                        anchors.centerIn: parent
                        spacing: 8 * root.u
                        LabelShared {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "\uf001"
                            font.pixelSize: 34 * root.u
                            color: Theme.alpha(Theme.bright, 0.33)
                        }
                        LabelShared {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Not playing"
                            font.pixelSize: 14 * root.u
                            color: Theme.alpha(Theme.bright, 0.5)
                        }
                    }

                    Item {
                        anchors.fill: parent
                        visible: media.pl !== null

                        CoverShared {
                            id: art
                            width: 100 * root.u
                            height: 100 * root.u
                            radius: root.rr(18)
                            fill: Theme.alpha(Theme.bright, 0.13)
                            glyph: "\uf001"
                            res: 200
                            url: track.art
                        }
                        Column {
                            x: 116 * root.u
                            width: parent.width - x
                            anchors.verticalCenter: art.verticalCenter
                            spacing: 4 * root.u
                            SwapTextShared {
                                width: parent.width
                                value: track.title
                                elide: Text.ElideRight
                                font.pixelSize: 17 * root.u
                                color: Theme.bright
                            }
                            SwapTextShared {
                                width: parent.width
                                value: track.artist
                                elide: Text.ElideRight
                                font.pixelSize: 13 * root.u
                                color: Theme.alpha(Theme.bright, 0.6)
                            }
                        }

                        SeekShared {
                            y: 126 * root.u
                            width: parent.width
                            player: media.pl
                            u: root.u
                            active: root.shown && !root.closing
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 176 * root.u
                            spacing: 18 * root.u
                            SkipButtonShared { anchors.verticalCenter: parent.verticalCenter; player: media.pl; dir: -1; size: 52 * root.u; glyphSize: 22 * root.u; tint: Theme.bright }
                            PlayButtonShared { anchors.verticalCenter: parent.verticalCenter; player: media.pl; size: 52 * root.u }
                            SkipButtonShared { anchors.verticalCenter: parent.verticalCenter; player: media.pl; dir: 1; size: 52 * root.u; glyphSize: 22 * root.u; tint: Theme.bright }
                        }

                        Music.Visualizer {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 34 * root.u
                            running: root.shown && !root.closing && media.pl !== null
                            intro: Theme.seg(root.t, 0.2)
                        }
                    }
                }

                Glass {
                    width: 340 * root.u
                    height: 350 * root.u
                    title: Qt.formatDate(new Date(root.calY, root.calM, 1), "MMMM yyyy")
                    delay: 0.12

                    Row {
                        anchors.right: parent.right
                        y: -34 * root.u
                        spacing: 2 * root.u
                        RoundIcon { size: 28 * root.u; glyph: "\uf053"; onClicked: root.shiftMonth(-1) }
                        RoundIcon { size: 28 * root.u; glyph: "\uf054"; onClicked: root.shiftMonth(1) }
                    }

                    Grid {
                        id: calGrid
                        width: parent.width
                        columns: 7
                        readonly property real cw: width / 7

                        SequentialAnimation {
                            id: monthFlip
                            NumberAnimation { target: calGrid; property: "opacity"; to: 0.1; duration: Theme.ms(90) }
                            NumberAnimation { target: calGrid; property: "opacity"; to: 1; duration: Theme.ms(280); easing.type: Easing.OutCubic }
                        }

                        Repeater {
                            model: ["M", "T", "W", "T", "F", "S", "S"]
                            delegate: Text {
                                required property string modelData
                                width: calGrid.cw
                                height: 26 * root.u
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                font.family: Theme.sans
                                font.pixelSize: 12 * root.u
                                color: Theme.alpha(Theme.bright, 0.4)
                            }
                        }
                        Repeater {
                            model: root.cells
                            delegate: Item {
                                id: cell
                                required property int modelData
                                width: calGrid.cw
                                height: 33 * root.u
                                readonly property bool today: modelData > 0
                                    && modelData === clock.date.getDate()
                                    && root.calM === clock.date.getMonth()
                                    && root.calY === clock.date.getFullYear()
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 28 * root.u
                                    height: width
                                    radius: width / 2
                                    visible: cell.today
                                    color: Theme.soft(Theme.accent)
                                }
                                LabelShared {
                                    anchors.centerIn: parent
                                    text: cell.modelData > 0 ? cell.modelData : ""
                                    font.pixelSize: 14 * root.u
                                    font.weight: cell.today ? Font.DemiBold : Font.Normal
                                    color: cell.today ? Theme.ink : Theme.alpha(Theme.bright, 0.9)
                                }
                            }
                        }
                    }
                }

                Glass {
                    width: root.sysW * root.u
                    height: 350 * root.u
                    title: "System"
                    delay: 0.18

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 14 * root.u
                        Gauge { ratio: root.cpu; label: "CPU"; valueText: Math.round(root.cpu * 100) + "%" }
                        Gauge { tint: Theme.accent2; ratio: 1 - root.memAvail / root.memTotal; label: "Memory"; valueText: Math.round((1 - root.memAvail / root.memTotal) * 100) + "%" }
                        Gauge { tint: Theme.info; visible: root.hasGpu; ratio: root.gpuUtil; label: "GPU"; valueText: Math.round(root.gpuUtil * 100) + "%" }
                        Gauge { tint: root.batPct < 20 && root.batState !== "Charging" ? Theme.warn : Theme.ok; visible: root.hasBattery; ratio: root.batPct / 100; label: root.batState === "Charging" ? "Charging" : "Battery"; valueText: root.batPct + "%" }
                    }

                    Row {
                        y: 112 * root.u
                        width: parent.width
                        height: 70 * root.u
                        spacing: 10 * root.u

                        Rectangle {
                            width: (parent.width - parent.spacing) / 2
                            height: parent.height
                            radius: root.rr(8)
                            color: Theme.alpha(Theme.bright, 0.07)

                            LabelShared {
                                x: 10 * root.u
                                y: 8 * root.u
                                text: "RAM"
                                font.pixelSize: 10 * root.u
                                color: Theme.alpha(Theme.bright, 0.5)
                            }
                            LabelShared {
                                x: 10 * root.u
                                y: 22 * root.u
                                width: parent.width - 20 * root.u
                                text: ((root.memTotal - root.memAvail) / 1048576).toFixed(1) + " / " + (root.memTotal / 1048576).toFixed(0) + " GB"
                                elide: Text.ElideRight
                                font.pixelSize: 9 * root.u
                                color: Theme.alpha(Theme.bright, 0.87)
                            }
                            Rectangle {
                                x: 10 * root.u
                                y: 42 * root.u
                                width: parent.width - 20 * root.u
                                height: 5 * root.u
                                radius: height / 2
                                color: Theme.alpha(Theme.bright, 0.13)
                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, 1 - root.memAvail / root.memTotal))
                                    height: parent.height
                                    radius: height / 2
                                    color: Theme.accent2
                                }
                            }
                            LabelShared {
                                x: 10 * root.u
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 7 * root.u
                                text: "AVAILABLE  " + (root.memAvail / 1048576).toFixed(1) + " GB"
                                font.pixelSize: 9 * root.u
                                color: Theme.alpha(Theme.bright, 0.44)
                            }
                        }

                        Rectangle {
                            width: (parent.width - parent.spacing) / 2
                            height: parent.height
                            radius: root.rr(8)
                            color: Theme.alpha(Theme.bright, 0.07)

                            LabelShared {
                                x: 10 * root.u
                                y: 8 * root.u
                                text: root.hasGpu ? "VRAM" : "MACHINE"
                                font.pixelSize: 10 * root.u
                                color: Theme.alpha(Theme.bright, 0.5)
                            }
                            LabelShared {
                                x: 10 * root.u
                                y: 22 * root.u
                                text: root.hasGpu ? root.gpuMemUsed.toFixed(1) + " / " + root.gpuMemTotal.toFixed(1) + " GB" : root.host
                                elide: Text.ElideRight
                                width: parent.width - 20 * root.u
                                font.pixelSize: 9 * root.u
                                color: Theme.alpha(Theme.bright, 0.87)
                            }
                            Rectangle {
                                x: 10 * root.u
                                y: 42 * root.u
                                width: parent.width - 20 * root.u
                                height: 5 * root.u
                                radius: height / 2
                                color: Theme.alpha(Theme.bright, 0.13)
                                visible: root.hasGpu
                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, root.gpuMemUsed / Math.max(0.1, root.gpuMemTotal)))
                                    height: parent.height
                                    radius: height / 2
                                    color: Theme.info
                                }
                            }
                            LabelShared {
                                x: 10 * root.u
                                y: 37 * root.u
                                width: parent.width - 20 * root.u
                                visible: !root.hasGpu
                                text: root.os || root.kernel
                                elide: Text.ElideRight
                                font.pixelSize: 10 * root.u
                                color: Theme.alpha(Theme.bright, 0.67)
                            }
                            LabelShared {
                                x: 10 * root.u
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 7 * root.u
                                text: root.hasGpu
                                    ? (root.gpuTemp > 0 ? "GPU TEMP  " + Math.round(root.gpuTemp) + "°C" : "DEDICATED GRAPHICS")
                                    : "KERNEL  " + root.kernel
                                elide: Text.ElideRight
                                width: parent.width - 20 * root.u
                                font.pixelSize: 9 * root.u
                                color: Theme.alpha(Theme.bright, 0.44)
                            }
                        }
                    }

                    Column {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        spacing: 6 * root.u
                        LabelShared {
                            width: parent.width
                            text: root.cpuModel
                            elide: Text.ElideRight
                            font.pixelSize: 12 * root.u
                            color: Theme.alpha(Theme.bright, 0.8)
                        }
                        LabelShared {
                            width: parent.width
                            text: (root.hasGpu ? root.gpuName + "  ·  " : "") + (root.memTotal / 1048576).toFixed(0) + " GB"
                            elide: Text.ElideRight
                            font.pixelSize: 12 * root.u
                            color: Theme.alpha(Theme.bright, 0.5)
                        }
                        LabelShared {
                            width: parent.width
                            text: "Up " + root.fmtUptime(root.uptime) + (root.cpuTemp > 0 ? "  ·  " + Math.round(root.cpuTemp) + "°C" : "")
                            font.pixelSize: 12 * root.u
                            color: Theme.alpha(Theme.bright, 0.5)
                        }
                    }
                }

                Column {
                    spacing: 20 * root.u

                    Item {
                        width: root.sysW * root.u
                        height: 110 * root.u

                        Glass {
                            anchors.fill: parent
                            title: "Volume"
                            delay: 0.24

                            LabelShared {
                                anchors.right: parent.right
                                y: -32 * root.u
                                text: AudioShared.muted ? "Muted" : Math.round(AudioShared.volume * 100) + "%"
                                font.pixelSize: 13 * root.u
                                color: Theme.alpha(Theme.bright, 0.6)
                            }

                            Item {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 34 * root.u

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: Theme.alpha(Theme.bright, 0.15)
                                    clip: true
                                    Rectangle {
                                        height: parent.height
                                        width: Math.max(parent.height, parent.width * (AudioShared.muted ? 0 : AudioShared.volume))
                                        radius: height / 2
                                        color: Theme.soft(Theme.info)
                                        Behavior on width { enabled: !volDrag.pressed; NumberAnimation { duration: Theme.ms(120); easing.type: Easing.OutCubic } }
                                    }
                                }
                                LabelShared {
                                    x: 13 * root.u
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: AudioShared.muted || AudioShared.volume === 0 ? "\uf026" : "\uf028"
                                    font.pixelSize: 15 * root.u
                                    color: Theme.on(Theme.info)
                                }
                                MouseArea {
                                    id: volDrag
                                    anchors.fill: parent
                                    preventStealing: true
                                    onPressed: mouse => AudioShared.setVolume(mouse.x / width)
                                    onPositionChanged: mouse => { if (pressed) AudioShared.setVolume(mouse.x / width) }
                                }
                                MouseArea {
                                    width: parent.height
                                    height: parent.height
                                    onClicked: AudioShared.toggleMute()
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            onWheel: wheel => AudioShared.setVolume(AudioShared.volume + wheel.angleDelta.y / 120 * 0.03)
                        }
                    }

                    Glass {
                        width: root.sysW * root.u
                        height: 220 * root.u
                        title: "Notifications" + (root.notifCount > 0 ? "  ·  " + root.notifCount : "")
                        delay: 0.3

                        Row {
                            anchors.right: parent.right
                            y: -34 * root.u
                            spacing: 2 * root.u
                            RoundIcon {
                                size: 28 * root.u
                                glyph: root.dnd ? "\uf1f6" : "\uf0f3"
                                tint: root.dnd ? Theme.accent2 : Theme.bright
                                onClicked: NotifsShared.dnd = !NotifsShared.dnd
                            }
                            RoundIcon {
                                size: 28 * root.u
                                glyph: "\uf1f8"
                                visible: root.notifCount > 0
                                onClicked: root.clearAll()
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            visible: root.notifCount === 0
                            spacing: 8 * root.u
                            LabelShared {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.dnd ? "\uf1f6" : "\uf0f3"
                                font.pixelSize: 34 * root.u
                                color: Theme.alpha(Theme.bright, 0.33)
                            }
                            LabelShared {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.dnd ? "Do Not Disturb" : "All clear"
                                font.pixelSize: 14 * root.u
                                color: Theme.alpha(Theme.bright, 0.5)
                            }
                        }

                        ListView {
                            id: notifList
                            anchors.fill: parent
                            clip: true
                            spacing: 8 * root.u
                            boundsBehavior: Flickable.StopAtBounds
                            model: ScriptModel { values: root.notifs }

                            delegate: NotificationCardShared {
                                required property var modelData
                                width: notifList.width
                                n: modelData
                                u: root.u
                            }

                            add: Transition {
                                ParallelAnimation {
                                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.ms(250) }
                                    NumberAnimation { property: "x"; from: 40 * root.u; duration: Theme.ms(320); easing.type: Easing.OutCubic }
                                }
                            }
                            remove: Transition {
                                ParallelAnimation {
                                    NumberAnimation { property: "opacity"; to: 0; duration: Theme.ms(180) }
                                    NumberAnimation { property: "x"; to: 60 * root.u; duration: Theme.ms(220); easing.type: Easing.InCubic }
                                }
                            }
                            displaced: Transition {
                                NumberAnimation { properties: "y"; duration: Theme.ms(250); easing.type: Easing.OutCubic }
                            }
                        }

                        Rectangle {
                            visible: notifList.contentHeight > notifList.height + 1
                            x: parent.width + 12 * root.u
                            y: parent.height * notifList.visibleArea.yPosition
                            width: 3 * root.u
                            height: parent.height * notifList.visibleArea.heightRatio
                            radius: width / 2
                            color: Theme.alpha(Theme.bright, 0.25)
                        }
                    }
                }
            }

            Glass {
                id: dock
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 64 * root.u
                width: dockRow.width + 32 * root.u
                height: 96 * root.u
                delay: 0.36

                Row {
                    id: dockRow
                    parent: dock
                    anchors.centerIn: parent
                    spacing: 16 * root.u
                    DockButton { glyph: "\uf023"; label: "Lock  L"; cmd: PowerShared.cmd("lock") }
                    DockButton { glyph: "\uf08b"; label: "Log Out  E"; cmd: PowerShared.cmd("logout") }
                    DockButton { glyph: "\uf021"; label: "Restart  R"; cmd: PowerShared.cmd("reboot") }
                    DockButton { glyph: "\uf011"; label: "Shut Down  S"; cmd: PowerShared.cmd("poweroff") }
                }
            }
        }
    }
}
