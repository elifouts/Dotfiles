import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../shared"
import "../common"

PanelWindow {
    id: home

    signal done()
    screen: Ui.target
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "retro-panel"
    WlrLayershell.keyboardFocus: Ui.touring ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

    property real t: 0
    Component.onCompleted: opening.start()
    NumberAnimation { id: opening; target: home; property: "t"; to: 1; duration: Theme.ms(260); easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: closing
        NumberAnimation { target: home; property: "t"; to: 0; duration: Theme.ms(180); easing.type: Easing.InCubic }
        ScriptAction { script: home.done() }
    }
    function close() { if (!closing.running) { opening.stop(); closing.start() } }
    function act(what) { close(); Ui.request(what) }

    StatsShared { id: st }
    SystemClock { id: clock; precision: SystemClock.Seconds }

    component Cell: Rectangle {
        id: cell
        property string big
        property string small
        property bool lit: false
        width: 104
        height: 46
        color: lit ? Theme.accent : "transparent"
        border.width: 1
        border.color: Theme.line
        Column {
            anchors.centerIn: parent
            Type { type: false; anchors.horizontalCenter: parent.horizontalCenter; text: cell.big; color: cell.lit ? Theme.bg : Theme.fg; font.pixelSize: Theme.size + 1 }
            Type { type: false; anchors.horizontalCenter: parent.horizontalCenter; text: cell.small; color: cell.lit ? Theme.bg : Theme.dim; font.pixelSize: Theme.size - 3 }
        }
    }
    component Read: Item {
        property string k
        property string v
        width: parent?.width ?? 300
        height: 20
        Type { text: parent.k; height: parent.height; color: Theme.dim }
        Type { type: false; caps: false; anchors.right: parent.right; width: parent.width - 100; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft; height: parent.height; text: parent.v; color: Theme.fg }
    }

    Item { anchors.fill: parent; focus: true; Keys.onPressed: home.close() }
    MouseArea { anchors.fill: parent; onClicked: home.close() }

    Tube {
        anchors.fill: parent
        t: home.t
        Rectangle { anchors.fill: parent; color: Theme.solid() }
        MouseArea { anchors.fill: page; onClicked: {} }

        Item {
            id: page
            anchors.centerIn: parent
            width: Math.min(1180, parent.width - 80)
            height: Math.min(parent.height - 80, body.implicitHeight)

            Column {
                anchors.right: parent.right
                Type { anchors.right: parent.right; text: Qt.formatDate(clock.date, "dddd"); color: Theme.fg; type: false }
                Type { anchors.right: parent.right; type: false; text: Qt.formatDate(clock.date, "dd MMM yy") + "   " + Theme.clock(clock.date, true, "AP"); color: Theme.fg }
            }

            Column {
                id: body
                width: parent.width
                spacing: 18

                Item { width: 1; height: 8 }
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4
                    Type { anchors.horizontalCenter: parent.horizontalCenter; text: Ui.host; font.pixelSize: 40; color: Theme.accent }
                    Rectangle { width: parent.width; height: 2; color: Theme.accent }
                }

                Row {
                    spacing: 18
                    Type { width: 230; height: 26; text: "quick keys"; font.pixelSize: Theme.size + 4; color: Theme.fg }
                    Repeater {
                        model: [["launcher", "run"], ["settings", "setup"], ["wallpaper", "screens"], ["overview", "tasks"], ["widgets", "widgets"]]
                        Button { required property var modelData; label: modelData[1]; height: 26; width: 112; primary: index === 0; required property int index; onPressed: home.act(modelData[0]) }
                    }
                }

                Row {
                    spacing: 18
                    Type { width: 230; height: 46; text: "live load"; font.pixelSize: Theme.size + 4; color: Theme.fg }
                    Cell { big: Math.round(st.cpu * 100) + "%"; small: "cpu"; lit: st.cpu > 0.85 }
                    Cell { big: Math.round(st.ram * 100) + "%"; small: "memory"; lit: st.ram > 0.85 }
                    Cell { visible: !!st.s.GPU; big: (st.gpu[1] || 0) + "%"; small: "gpu" }
                    Cell { visible: !!st.s.GPU; big: (st.gpu[4] || "--") + "°c"; small: "gpu temp" }
                    Cell { visible: !!st.s.CPUT; big: Math.round((st.s.CPUT || 0) / 1000) + "°c"; small: "cpu temp" }
                    Cell { big: SystemStatsShared.net.toLowerCase(); small: "link"; lit: SystemStatsShared.net === "OFFLINE" }
                }

                Row {
                    spacing: 18
                    Type { width: 230; height: 46; text: "session"; font.pixelSize: Theme.size + 4; color: Theme.fg }
                    Cell { big: st.uptime(parseFloat(st.s.UP || 0)); small: "uptime" }
                    Cell { big: Hyprland.toplevels.values.length; small: "windows" }
                    Cell { big: HyprShared.workspaces.length; small: "workspaces" }
                    Cell { big: Math.round(AudioShared.volume * 100) + "%"; small: AudioShared.muted ? "muted" : "volume"; lit: AudioShared.muted }
                    Cell { visible: PowerShared.hasBattery; big: Math.round(PowerShared.charge * 100) + "%"; small: PowerShared.charging ? "charging" : "battery" }
                    Cell { big: NotifsShared.count; small: NotifsShared.dnd ? "do not disturb" : "messages" }
                }

                Type { caps: true; text: "this terminal is using the " + (StoreShared.colorTheme === "pywal" ? "wallpaper" : StoreShared.colorTheme.split("/").pop()) + " palette"; color: Theme.dim; font.pixelSize: Theme.size - 2 }

                Row {
                    spacing: 18
                    Box {
                        width: (page.width - 36) / 3
                        height: 196
                        title: "system"
                        Column {
                            x: 16; y: 18; width: parent.width - 32; spacing: 2
                            Read { k: "os"; v: st.s.OS || "" }
                            Read { k: "kernel"; v: st.s.KERN || "" }
                            Read { k: "user"; v: Quickshell.env("USER") }
                            Read { k: "cpu"; v: st.s.CPUM || "" }
                            Read { visible: !!st.s.GPU; k: "gpu"; v: st.gpu[0] || "" }
                            Read { k: "memory"; v: st.gb(st.s.MemTotal - st.s.MemAvailable || 0, st.s.MemTotal || 0, 1048576) }
                            Read { visible: !!st.s.GPU; k: "vram"; v: st.gb(parseFloat(st.gpu[2]) || 0, parseFloat(st.gpu[3]) || 0, 1024) }
                        }
                    }
                    Box {
                        width: (page.width - 36) / 3
                        height: 196
                        title: "tasks"
                        Column {
                            x: 10; y: 16; width: parent.width - 20
                            Repeater {
                                model: Hyprland.toplevels.values.slice(0, 8)
                                Controls.Line {
                                    required property var modelData
                                    glyph: String(modelData.workspace?.id ?? "-")
                                    text: modelData.title
                                    value: (modelData.lastIpcObject?.class || "").split(".").pop()
                                    lit: modelData.activated
                                    onClicked: { HyprShared.focusWindow(modelData.address); home.close() }
                                }
                            }
                        }
                    }
                    Box {
                        width: (page.width - 36) / 3
                        height: 196
                        title: "now playing"
                        MediaCard { x: 16; y: 0; width: parent.width - 32; height: parent.height; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }
    }
}
