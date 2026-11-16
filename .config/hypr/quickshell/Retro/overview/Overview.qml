import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../shared"
import "../common"

PanelWindow {
    id: ov

    signal done()
    screen: Ui.target
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "retro-panel"
    WlrLayershell.keyboardFocus: Ui.touring ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

    property real t: 0
    Component.onCompleted: { Hyprland.refreshToplevels(); grow.start() }
    NumberAnimation { id: grow; target: ov; property: "t"; to: 1; duration: Theme.ms(240); easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: shut
        NumberAnimation { target: ov; property: "t"; to: 0; duration: Theme.ms(160); easing.type: Easing.InCubic }
        ScriptAction { script: ov.done() }
    }
    function close() { if (!shut.running) { grow.stop(); shut.start() } }

    readonly property var rows: {
        const out = []
        for (const id of HyprShared.workspaceIds) {
            const wins = Hyprland.toplevels.values.filter(w => w.workspace?.id === id)
            if (!wins.length) out.push({ ws: id, win: null })
            for (const w of wins) out.push({ ws: id, win: w })
        }
        for (const w of Hyprland.toplevels.values.filter(w => (w.workspace?.id ?? 0) < 0)) out.push({ ws: w.workspace?.name?.replace("special:", "s:") ?? "s", win: w })
        return out
    }
    property int sel: Math.max(0, rows.findIndex(r => r.win?.activated))
    function pick(i) {
        const r = rows[i]
        if (!r) return
        if (r.win) HyprShared.focusWindow(r.win.address)
        else HyprShared.focusWs(r.ws)
        close()
    }
    function shut_(i) { const r = rows[i]; if (r?.win) HyprShared.dispatch("hl.dsp.window.close({ window = \"address:0x" + r.win.address + "\" })", "closewindow address:0x" + r.win.address) }

    MouseArea { anchors.fill: parent; onClicked: ov.close() }

    Tube {
        id: frame
        anchors.centerIn: parent
        width: Math.min(1100, ov.width - 80)
        height: Math.min(ov.height - 100, list.contentHeight + 120)
        t: ov.t

        Box { anchors.fill: parent; double: true; title: "tasks"; note: "esc-end" }
        MouseArea { anchors.fill: parent }

        Row {
            id: head
            x: 22; y: 22
            spacing: 0
            Repeater {
                model: [["ws", 70], ["class", 200], ["title", frame.width - 44 - 70 - 200 - 120], ["mon", 120]]
                Type { required property var modelData; width: modelData[1]; height: 22; text: modelData[0]; color: Theme.accent }
            }
        }
        Rectangle { x: 22; y: 46; width: frame.width - 44; height: 1; color: Theme.low }

        ListView {
            id: list
            x: 22; y: 52
            width: frame.width - 44
            height: frame.height - 80
            clip: true
            model: ov.rows
            currentIndex: ov.sel
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0
            delegate: Rectangle {
                id: r
                required property var modelData
                required property int index
                readonly property bool on: index === ov.sel
                readonly property bool first: index === 0 || ov.rows[index - 1].ws !== modelData.ws
                readonly property color ink: on ? Theme.bg : modelData.win ? (modelData.win.activated ? Theme.accent : Theme.fg) : Theme.dim
                width: list.width
                height: 22
                color: on ? Theme.accent : ra.containsMouse ? Theme.low : "transparent"
                Row {
                    height: parent.height
                    Type { type: false; width: 70; height: parent.height; text: r.first ? String(r.modelData.ws).padStart(2, "0") : "  ·"; color: r.ink }
                    Type { type: false; width: 200; height: parent.height; elide: Text.ElideRight; text: r.modelData.win ? (r.modelData.win.lastIpcObject?.class || r.modelData.win.appId || "?").split(".").pop() : "empty"; color: r.ink }
                    Type { type: false; caps: false; width: list.width - 390; height: parent.height; elide: Text.ElideRight; text: r.modelData.win?.title ?? ""; color: r.ink }
                    Type { type: false; width: 120; height: parent.height; text: r.modelData.win?.monitor?.name ?? ""; color: r.on ? Theme.bg : Theme.dim }
                }
                MouseArea { id: ra; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.MiddleButton; onClicked: m => m.button === Qt.MiddleButton ? ov.shut_(r.index) : ov.pick(r.index); onEntered: ov.sel = r.index }
            }
        }
    }

    Item {
        focus: true
        Keys.onEscapePressed: ov.close()
        Keys.onReturnPressed: ov.pick(ov.sel)
        Keys.onEnterPressed: ov.pick(ov.sel)
        Keys.onPressed: e => {
            const n = parseInt(e.text)
            if (e.key === Qt.Key_Down || e.text === "j") ov.sel = Math.min(ov.rows.length - 1, ov.sel + 1)
            else if (e.key === Qt.Key_Up || e.text === "k") ov.sel = Math.max(0, ov.sel - 1)
            else if (e.key === Qt.Key_Tab) ov.close()
            else if (e.text === "x") ov.shut_(ov.sel)
            else if (n >= 1 && n <= 9) { HyprShared.focusWs(n); ov.close() }
            else return
            e.accepted = true
        }
    }
}
