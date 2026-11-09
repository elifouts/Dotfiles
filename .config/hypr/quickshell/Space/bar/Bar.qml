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
    WatchedShared { id: lookFile; path: Quickshell.shellPath("../Space/quickshellbar/" + (nameFile.text().trim() || "default") + "/config.json") }
    readonly property var look: {
        const d = { left: ["user", "workspaces"], center: [], right: ["media", "timer", "updates", "network", "audio", "battery", "tray", "notifications", "clock", "power"], attached: false }
        try { return Object.assign(d, JSON.parse(lookFile.text())) } catch (e) { return d }
    }
    readonly property bool attached: look.attached === true

    anchors { top: true; left: true; right: true }
    margins { top: attached ? 0 : 8; left: 12; right: 12 }
    implicitHeight: 28 + Math.min(640, (screen?.height ?? 900) * 0.7)
    exclusiveZone: Ui.bar ? 28 : 0
    visible: Ui.bar
    updatesEnabled: !Ui.covered
    color: "transparent"
    WlrLayershell.namespace: "space-bar"
    WlrLayershell.keyboardFocus: Ui.panel !== "" && Ui.panelScreen === screen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { Region { item: lw } Region { item: cw } Region { item: rw } }

    component Side: Pill {
        id: side
        property var names: []
        visible: names.length > 0
        scr: bar.screen
        active: bar.visible
        attached: bar.attached
        Repeater {
            model: side.names
            Loader { required property string modelData; height: 28; sourceComponent: bar.mods[modelData] ?? null }
        }
    }
    Side { id: lw; lean: 1; names: bar.look.left }
    Side { id: cw; lean: 0; introDelay: 45; x: (bar.width - width) / 2; names: bar.look.center }
    Side { id: rw; lean: -1; introDelay: 90; anchors.right: parent.right; names: bar.look.right }

    readonly property var mods: ({ user: user, workspaces: workspaces, media: media, timer: timer, updates: updates, network: network,
        audio: audio, battery: battery, tray: tray, notifications: notifications, clock: clock, power: power, "|": divider })
    Component { id: user; Module { glyph: "󰀄"; text: Quickshell.env("USER"); panel: "home" } }
    Component { id: workspaces; Workspaces {} }
    Component { id: media; Module { glyph: "󰝚"; panel: "media" } }
    Component { id: timer; Module { decode: false; show: TimerForecast.timer.active; glyph: "󰔛"; text: TimerForecast.timer.format(TimerForecast.timer.remaining); panel: "media"; tab: "timer"; hot: !TimerForecast.timer.running } }
    Component { id: updates; Module { show: UpdatesShared.count > 0; glyph: "󰚰"; text: UpdatesShared.count; panel: "updates" } }
    Component { id: network; Module { glyph: SystemStatsShared.net === "OFFLINE" ? "󰤭" : SystemStatsShared.net === "WLAN" ? "󰤨" : "󰈀"; panel: "net"; hot: SystemStatsShared.net === "OFFLINE" } }
    Component {
        id: audio
        Module {
            glyph: AudioShared.muted ? "󰝟" : "󰕾"
            panel: "audio"
            room: 66
            onWheel: dir => AudioShared.nudge(dir)
            Slider {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 60
                cells: 12
                scrollable: false
                value: Math.min(1, AudioShared.volume)
                dimmed: AudioShared.muted
                onMoved: v => AudioShared.setVolume(v)
            }
        }
    }
    Component {
        id: battery
        Module {
            show: PowerShared.hasBattery
            glyph: PowerShared.charging ? "󰂄" : "󰁹"
            text: Math.round(PowerShared.charge * 100)
            panel: "power"
            hot: PowerShared.discharging && PowerShared.charge < 0.15
        }
    }
    Component { id: tray; Module { show: SystemTray.items.values.length > 0; glyph: "󱊔"; panel: "tray" } }
    Component { id: notifications; Module { glyph: NotifsShared.dnd ? "󰂛" : "󰂚"; text: NotifsShared.count || ""; panel: "notifs" } }
    Component {
        id: clock
        Module {
            SystemClock { id: time; precision: SystemClock.Minutes }
            text: Theme.clock(time.date, false, "ap")
            panel: "time"
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton; onClicked: Ui.openPanel("media", bar.screen, "timer") }
        }
    }
    Component { id: power; Module { glyph: "󰐥"; panel: "power"; show: !PowerShared.hasBattery } }
    Component { id: divider; Item { width: 1; Rectangle { anchors.centerIn: parent; width: 1; height: 12; color: Theme.alpha(Theme.accent, 0.3) } } }
}
