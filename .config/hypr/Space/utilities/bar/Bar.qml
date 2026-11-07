import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
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

    Wing {
        id: lw
        lean: 1
        introDelay: 0
        scr: bar.screen
        active: bar.visible
        Chip { glyph: "󰀄"; text: Quickshell.env("USER"); panel: "scan" }
        Stars {}
    }

    Wing {
        id: rw
        lean: -1
        padR: 0
        introDelay: 90
        scr: bar.screen
        active: bar.visible
        anchors.right: parent.right
        Chip { glyph: "󰝚"; panel: "media" }
        Chip { decode: false; show: Live.timer.active; glyph: "󰔛"; text: Live.timer.format(Live.timer.remaining); panel: "media"; tab: "timer"; hot: !Live.timer.running }
        Chip { show: UpdatesShared.count > 0; glyph: "󰚰"; text: UpdatesShared.count; panel: "updates" }
        Chip { glyph: Sys.net === "OFFLINE" ? "󰤭" : Sys.net === "WLAN" ? "󰤨" : "󰈀"; panel: "net"; hot: Sys.net === "OFFLINE" }
        Chip {
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
        Chip {
            show: PowerShared.hasBattery
            glyph: PowerShared.charging ? "󰂄" : "󰁹"
            text: Math.round(PowerShared.charge * 100)
            panel: "power"
            hot: PowerShared.discharging && PowerShared.charge < 0.15
        }
        Chip { show: SystemTray.items.values.length > 0; glyph: "󱊔"; panel: "tray" }
        Chip { glyph: NotifsShared.dnd ? "󰂛" : "󰂚"; text: NotifsShared.count || ""; panel: "notifs" }
        Chip {
            SystemClock { id: clock; precision: SystemClock.Minutes }
            glyph: "󰥔"
            text: Qt.formatTime(clock.date, StoreShared.values["space.clock24"] === false ? "h:mm ap" : "HH:mm")
            panel: "time"
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton; onClicked: Ui.openPanel("media", bar.screen, "timer") }
        }
        Chip { glyph: "󰐥"; panel: "power"; show: !PowerShared.hasBattery }
    }
}
