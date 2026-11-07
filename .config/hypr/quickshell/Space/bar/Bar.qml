import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "../../shared"
import "../common"

PanelWindow {
    id: bar

    anchors { top: true; left: true; right: true }
    margins { top: 8; left: 12; right: 12 }
    implicitHeight: 28 + Math.min(640, (screen?.height ?? 900) * 0.7)
    exclusiveZone: Ui.bar ? 28 : 0
    visible: Ui.bar
    color: "transparent"
    WlrLayershell.namespace: "space-bar"
    WlrLayershell.keyboardFocus: Ui.panel !== "" && Ui.panelScreen === screen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { Region { item: lw } Region { item: rw } }

    Pill {
        id: lw
        lean: 1
        introDelay: 0
        scr: bar.screen
        active: bar.visible
        Module { glyph: "󰀄"; text: Quickshell.env("USER"); panel: "home" }
        Workspaces {}
    }

    Pill {
        id: rw
        lean: -1
        padR: 0
        introDelay: 90
        scr: bar.screen
        active: bar.visible
        anchors.right: parent.right
        Module { glyph: "󰝚"; panel: "media" }
        Module { decode: false; show: TimerForecast.timer.active; glyph: "󰔛"; text: TimerForecast.timer.format(TimerForecast.timer.remaining); panel: "media"; tab: "timer"; hot: !TimerForecast.timer.running }
        Module { show: UpdatesShared.count > 0; glyph: "󰚰"; text: UpdatesShared.count; panel: "updates" }
        Module { glyph: SystemStats.net === "OFFLINE" ? "󰤭" : SystemStats.net === "WLAN" ? "󰤨" : "󰈀"; panel: "net"; hot: SystemStats.net === "OFFLINE" }
        Module {
            glyph: AudioShared.muted ? "󰝟" : "󰕾"
            panel: "audio"
            room: 66
            onWheel: dir => AudioShared.nudge(dir)
            Slider {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 60
                cells: 12
                scrollable: false
                value: Math.min(1, AudioShared.volume)
                dimmed: AudioShared.muted
                onMoved: v => AudioShared.setVolume(v)
            }
        }
        Module {
            show: PowerShared.hasBattery
            glyph: PowerShared.charging ? "󰂄" : "󰁹"
            text: Math.round(PowerShared.charge * 100)
            panel: "power"
            hot: PowerShared.discharging && PowerShared.charge < 0.15
        }
        Module { show: SystemTray.items.values.length > 0; glyph: "󱊔"; panel: "tray" }
        Module { glyph: NotifsShared.dnd ? "󰂛" : "󰂚"; text: NotifsShared.count || ""; panel: "notifs" }
        Module {
            SystemClock { id: clock; precision: SystemClock.Minutes }
            glyph: "󰥔"
            text: Theme.clock(clock.date, false, "ap")
            panel: "time"
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton; onClicked: Ui.openPanel("media", bar.screen, "timer") }
        }
        Module { glyph: "󰐥"; panel: "power"; show: !PowerShared.hasBattery }
    }
}
