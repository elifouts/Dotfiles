import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "../../shared"
import "../common"

PanelWindow {
    id: bar

    WatchedShared { id: nameFile; path: HyprShared.state + "/bar-style" }
    WatchedShared { id: lookFile; path: Quickshell.shellPath("../Retro/quickshellbar/" + (nameFile.text().trim() || "default") + "/config.json") }
    readonly property var look: {
        const d = { left: ["user", "workspaces"], center: [], right: ["cpu", "mem", "media", "timer", "updates", "network", "audio", "battery", "tray", "notifications", "clock", "power"], attached: true }
        try { return Object.assign(d, JSON.parse(lookFile.text())) } catch (e) { return d }
    }
    readonly property bool strip: look.attached === true
    readonly property int gap: strip ? 0 : 6

    anchors { top: true; left: true; right: true }
    margins { top: gap; left: gap; right: gap }
    implicitHeight: Theme.bar + Math.min(640, (screen?.height ?? 900) * 0.7)
    exclusiveZone: Ui.bar ? Theme.bar + (strip ? 0 : 2) : 0
    visible: Ui.bar
    color: "transparent"
    WlrLayershell.namespace: "retro-bar"
    WlrLayershell.keyboardFocus: Ui.panel !== "" && Ui.panelScreen === screen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { Region { item: back } Region { item: lw } Region { item: cw } Region { item: rw } Region { item: dropHit } }

    Rectangle {
        id: back
        visible: bar.strip
        width: bar.width
        height: bar.strip ? Theme.bar : 0
        color: Theme.solid()
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.line }
    }

    readonly property int inset: strip ? 18 : 0
    component Side: Pill {
        id: side
        readonly property real nat: need([])
        property var names: []
        visible: names.length > 0
        scr: bar.screen
        framed: !bar.strip
        function need(cut) {
            let w = 16, n = 0
            for (let i = 0; i < rep.count; i++) {
                const l = rep.itemAt(i), it = l?.item
                if (!it || cut.includes(l.modelData)) continue
                w += "natural" in it ? it.natural : it.implicitWidth
                n++
            }
            return n ? w + (n - 1) * 10 : 0
        }
        Repeater {
            id: rep
            model: side.names
            Loader {
                id: ld
                required property string modelData
                height: Theme.bar
                sourceComponent: bar.mods[modelData] ?? null
                Binding { when: !!ld.item && "cut" in ld.item; target: ld.item; property: "cut"; value: bar.cut.includes(ld.modelData) }
            }
        }
    }
    readonly property var spare: ["cpu", "mem", "updates", "|", "network", "media", "tray", "user", "battery", "timer", "notifications", "audio"]
    property var cut: []
    function fit() {
        const room = bar.width - 2 * bar.inset - 24
        for (let n = 0; n <= spare.length; n++) {
            const c = spare.slice(0, n), l = lw.need(c), m = cw.need(c), r = rw.need(c)
            if ((m ? 2 * Math.max(l, r) + m + 24 : l + r) <= room) { if (String(c) !== String(cut)) cut = c; return }
        }
        cut = spare
    }
    Timer { id: refit; interval: 60; onTriggered: bar.fit() }
    onWidthChanged: refit.restart()
    onLookChanged: refit.restart()
    Component.onCompleted: refit.restart()
    Side { id: lw; x: bar.inset; names: bar.look.left; onNatChanged: refit.restart() }
    Side { id: cw; x: (bar.width - width) / 2; names: bar.look.center; onNatChanged: refit.restart() }
    Side { id: rw; x: bar.width - width - bar.inset; names: bar.look.right; onNatChanged: refit.restart() }

    Item {
        id: dropHit
        x: drop.x
        y: Theme.bar - 1
        width: drop.on ? drop.width : 0
        height: drop.on ? drop.y + drop.height - y : 0
        HoverHandler { id: dropHover; onHoveredChanged: if (hovered) drop.touched = true }
    }
    Item {
        id: drop
        readonly property bool on: Ui.panel !== "" && Ui.panelScreen === bar.screen
        property string kind: ""
        property bool touched: false
        onOnChanged: if (on) { kind = Ui.panel; touched = false }
        Connections { target: Ui; function onPanelChanged() { if (drop.on) drop.kind = Ui.panel } }
        readonly property real w: ({ media: 500, net: 440, audio: 440, time: 400, notifs: 420 })[kind] ?? 380
        property real t: on ? 1 : 0
        Behavior on t { NumberAnimation { duration: Theme.open; easing.type: Easing.OutCubic } }
        visible: t > 0.01
        width: w
        height: body.height + 40
        x: Math.max(8, Math.min(bar.width - w - 8, (Ui.owner ? Ui.ax : bar.width / 2) - w / 2))
        y: Theme.bar + 6
        Behavior on x { enabled: drop.t > 0.99; NumberAnimation { duration: Theme.open; easing.type: Easing.OutCubic } }
        Behavior on width { enabled: drop.t > 0.99; NumberAnimation { duration: Theme.open; easing.type: Easing.OutCubic } }
        Behavior on height { enabled: drop.t > 0.99; NumberAnimation { duration: Theme.open; easing.type: Easing.OutCubic } }
        transform: Scale { yScale: Math.max(0.02, drop.t) }
        opacity: Math.min(1, drop.t * 2)

        HoverHandler { id: inHover; onHoveredChanged: if (hovered) drop.touched = true }
        Box { anchors.fill: parent; title: body.item?.card ?? ({ time: "calendar", media: "media", net: "network", audio: "sound", notifs: "notifications", power: "power", updates: "updates" })[drop.kind] ?? "" }
        Loader {
            id: body
            x: 16
            y: 22
            width: drop.w - 32
            source: drop.kind ? ({ audio: "../../shared/SoundShared", media: "menus/Island", net: "../../shared/NetworkShared", notifs: "../../shared/NotificationsShared", power: "menus/Session", time: "menus/Calendar", tray: "menus/Tray", updates: "../../shared/UpdateMenuShared" })[drop.kind] + ".qml" : ""
            onLoaded: if ("open" in item) item.open = Qt.binding(() => drop.on)
        }
        Connections {
            target: body.item
            ignoreUnknownSignals: true
            function onRun(cmd) { HyprShared.run(cmd) }
            function onDone() { Ui.panel = "" }
        }
        Timer {
            interval: 260
            running: drop.on && (!!Ui.owner || drop.touched) && !dropHover.hovered && !inHover.hovered && !(Ui.owner?.hovered ?? false) && !body.item?.holdOpen
            onTriggered: Ui.panel = ""
        }
    }

    readonly property var mods: ({ user: user, workspaces: workspaces, media: media, timer: timer, updates: updates, network: network, audio: audio,
        battery: battery, tray: tray, notifications: notifications, clock: clock, date: null, cpu: cpu, mem: mem, power: power, "|": divider })
    Component { id: user; Module { glyph: ">"; text: Quickshell.env("USER") + "@" + Ui.host; panel: "home" } }
    Component { id: workspaces; Workspaces {} }
    Component {
        id: media
        Module {
            NowPlayingShared { id: now; player: MediaShared.pickPlayer("") }
            readonly property string song: [now.title, now.artist].filter(x => x).join(" - ")
            glyph: "󰝚"
            text: song.length > 36 ? song.slice(0, 35) + "…" : song
            panel: "media"
        }
    }
    Component { id: timer; Module { type: false; show: TimerForecast.timer.active; label: "tmr"; text: TimerForecast.timer.format(TimerForecast.timer.remaining); panel: "media"; tab: "timer"; hot: !TimerForecast.timer.running } }
    Component { id: updates; Module { show: UpdatesShared.count > 0; label: "upd"; text: UpdatesShared.count; panel: "updates" } }
    Component { id: network; Module { label: "net"; text: SystemStatsShared.net.toLowerCase(); panel: "net"; hot: SystemStatsShared.net === "OFFLINE" } }
    Component { id: cpu; Module { type: false; label: "cpu"; text: String(Math.round(SystemStatsShared.cpu * 100)).padStart(2, "0") + "%"; panel: "home"; hot: SystemStatsShared.cpu > 0.9 } }
    Component { id: mem; Module { type: false; label: "mem"; text: String(Math.round(SystemStatsShared.ram * 100)).padStart(2, "0") + "%"; panel: "home"; hot: SystemStatsShared.ram > 0.9 } }
    Component {
        id: audio
        Module {
            type: false
            label: AudioShared.muted ? "mute" : "vol"
            text: String(Math.round(AudioShared.volume * 100)).padStart(2, "0") + "%"
            panel: "audio"
            onWheel: dir => AudioShared.nudge(dir)
        }
    }
    Component {
        id: battery
        Module {
            show: PowerShared.hasBattery
            type: false
            label: PowerShared.charging ? "chg" : "bat"
            text: Math.round(PowerShared.charge * 100) + "%"
            panel: "power"
            hot: PowerShared.discharging && PowerShared.charge < 0.15
        }
    }
    Component { id: tray; Module { show: SystemTray.items.values.length > 0; label: "tray"; text: SystemTray.items.values.length; panel: "tray" } }
    Component { id: notifications; Module { label: NotifsShared.dnd ? "dnd" : "msg"; text: NotifsShared.count || "0"; panel: "notifs" } }
    Component {
        id: clock
        Module {
            type: false
            SystemClock { id: time; precision: SystemClock.Minutes }
            text: Qt.formatDate(time.date, "ddd dd MMM yy") + "  " + Theme.clock(time.date, false, "AP")
            panel: "time"
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton; onClicked: Ui.openPanel("media", bar.screen, "timer") }
        }
    }
    Component { id: power; Module { glyph: "⏻"; panel: "power"; show: !PowerShared.hasBattery } }
    Component { id: divider; Item { property bool cut: false; readonly property real natural: 8; visible: !cut; width: 8; height: Theme.bar; Text { anchors.centerIn: parent; text: "│"; font.family: Theme.font; font.pixelSize: Theme.size; color: Theme.low } } }
}
