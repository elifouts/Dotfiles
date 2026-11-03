import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "../common"

// floating framed hud: two chamfered glass frames with corner brackets
PanelWindow {
    id: bar

    anchors { top: true; left: true; right: true }
    margins { top: 8; left: 12; right: 12 }
    // tall enough for the biggest dropdown up front, so opening one never resizes the surface
    implicitHeight: 28 + Math.min(640, (screen?.height ?? 900) * 0.7)
    exclusiveZone: Ui.bar ? 28 : 0
    visible: Ui.bar
    color: "transparent"
    WlrLayershell.namespace: "space-bar"
    WlrLayershell.keyboardFocus: Ui.panel !== "" && Ui.panelScreen === screen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    // only the frames take input, the strip between them stays click-through
    mask: Region { Region { item: lw } Region { item: rw } }

    readonly property bool narrow: width < 1300
    readonly property var player: Media.pickPlayer("")

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
        // what's playing, and the way into timer, color, capture and weather
        Chip {
            readonly property string title: bar.narrow ? "" : bar.player?.trackTitle ?? ""
            glyph: !bar.player ? "󰝚" : Media.playing(bar.player) ? "󰎈" : "󰏤"
            text: title.length > 24 ? title.slice(0, 23) + "…" : title
            panel: "media"
        }
        Chip { show: Live.timer.active; glyph: "󰔛"; text: Live.timer.format(Live.timer.remaining); panel: "media"; tab: "timer"; hot: !Live.timer.running }
        Chip { show: Updates.count > 0; glyph: "󰚰"; text: Updates.count; panel: "updates" }
        Chip { glyph: Sys.net === "OFFLINE" ? "󰤭" : Sys.net === "WLAN" ? "󰤨" : "󰈀"; panel: "net"; hot: Sys.net === "OFFLINE" }
        Chip { glyph: Audio.muted ? "󰝟" : "󰕾"; text: Audio.muted ? "" : Math.round(Audio.volume * 100); panel: "audio" }
        Chip {
            show: Power.hasBattery
            glyph: Power.charging ? "󰂄" : "󰁹"
            text: Math.round(Power.charge * 100)
            panel: "power"
            hot: Power.discharging && Power.charge < 0.15
        }
        Chip { show: SystemTray.items.values.length > 0; glyph: "󰇘"; panel: "tray" }
        Chip { glyph: Notifs.dnd ? "󰂛" : "󰂚"; text: Notifs.count || ""; panel: "notifs" }
        Chip {
            SystemClock { id: clock; precision: SystemClock.Minutes }
            glyph: "󰥔"
            text: Qt.formatTime(clock.date, Store.values["space.clock24"] === false ? "h:mm ap" : "HH:mm")
            panel: "time"
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton; onClicked: Ui.openPanel("media", bar.screen, "timer") }
        }
        Chip { glyph: "󰐥"; panel: "power"; show: !Power.hasBattery }
    }
}
