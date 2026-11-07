import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../shared"
import "../common"
import "../common/decode.js" as Decode

PanelWindow {
    id: win

    signal done()
    screen: Ui.target
    anchors.top: true
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Math.min(620, (screen?.width ?? 800) - 40)
    implicitHeight: 300 + rest
    mask: Region { item: frame }
    color: "transparent"
    WlrLayershell.namespace: "space-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.touring ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

    property int sel: 0
    property bool cmd: false
    property var cmds: []
    onCmdChanged: if (cmd && !cmds.length) scan.running = true
    Process {
        id: scan
        command: ["python3", HyprShared.util + "/launcher.py", "commands"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { win.cmds = JSON.parse(text).map(e => ({ name: e.n, genericName: e.k === "bin" ? "" : e.d })) } catch (e) {}
            }
        }
    }
    readonly property real rest: 42
    property real t: 0
    Component.onCompleted: grow.start()
    function close() { if (!shut.running) { grow.stop(); shut.start() } }
    SettleShared { id: grow; target: win; property: "t"; to: 1; duration: Theme.open }
    SequentialAnimation {
        id: shut
        SettleShared { target: win; property: "t"; to: 0; duration: Theme.quick; easing.bezierCurve: Theme.leave }
        ScriptAction { script: win.done() }
    }

    HyprlandFocusGrab { active: !Ui.touring; windows: [win]; onCleared: win.close() }

    function score(q, s) {
        s = (s || "").toLowerCase()
        let i = 0, pts = 0, run = 0
        for (let j = 0; j < s.length && i < q.length; j++) {
            if (s[j] !== q[i]) { run = 0; continue }
            run++
            pts += run * 2 + (j === 0 || " -_.".includes(s[j - 1]) ? 6 : 0)
            i++
        }
        return i === q.length ? pts - s.length * 0.05 + (s === q ? 100 : s.startsWith(q) ? 20 : 0) : -1
    }
    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)
    readonly property var hits: {
        const line = field.text.trim(), q = line.toLowerCase()
        if (!q) return []
        const key = cmd ? q.split(/\s+/)[0] : q
        const found = (cmd ? cmds : apps).map(a => [a, Math.max(score(key, a.name) * 1.5, score(key, a.genericName), score(key, (a.keywords || []).join(" ")))])
            .filter(x => x[1] >= 0).sort((a, b) => b[1] - a[1]).map(x => x[0])
        if (!cmd) return found.slice(0, 7)
        const typed = { name: line, genericName: "run as typed" }
        if (/\s/.test(q)) return [typed, ...found.slice(0, 6)]
        return found[0]?.name.toLowerCase() === q ? found.slice(0, 7) : [...found.slice(0, 6), typed]
    }
    onHitsChanged: sel = 0

    function launch(background) {
        const a = hits[sel]
        if (a?.execute) a.execute()
        else if (a) Quickshell.execDetached((background ? [] : ["kitty", "--hold", "env", "NOFETCH=1"]).concat(["bash", "-ic", a.name]))
        close()
    }

    Item {
        id: drop
        width: parent.width
        height: frame.height
        y: -height + (win.rest + height) * win.t

        Rectangle {
            id: frame
            width: parent.width
            height: col.height + 26
            color: Theme.back(0.8)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.3)
            Rectangle { width: 3; height: parent.height; color: Theme.accent }

            Column {
                id: col
                x: 18
                y: 12
                width: parent.width - 36
                spacing: 3

                Row {
                    spacing: 8
                    DecodeText { text: win.cmd ? "~/cmd" : "~/run"; color: Theme.accent; font.capitalization: Font.MixedCase; height: 22 }
                    DecodeText { text: "$"; color: Theme.dim; height: 22 }
                    TextInput {
                        id: field
                        cursorDelegate: Item {}
                        clip: true
                        width: col.width - 90
                        height: 22
                        verticalAlignment: TextInput.AlignVCenter
                        focus: true
                        font.family: Theme.font
                        font.pixelSize: 14
                        color: Theme.fg
                        cursorVisible: false
                        selectionColor: Theme.alpha(Theme.accent, 0.4)
                        Keys.onEscapePressed: win.close()
                        Keys.onReturnPressed: event => win.launch(event.modifiers & Qt.ShiftModifier)
                        Keys.onEnterPressed: event => win.launch(event.modifiers & Qt.ShiftModifier)
                        Keys.onDownPressed: win.sel = Math.min(win.hits.length - 1, win.sel + 1)
                        Keys.onUpPressed: win.sel = Math.max(0, win.sel - 1)
                        Keys.onTabPressed: win.cmd = !win.cmd
                        Rectangle {
                            x: field.cursorRectangle.x
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8; height: 15
                            color: Theme.accent
                            SequentialAnimation on opacity { loops: Animation.Infinite; NumberAnimation { to: 0; duration: 500 } NumberAnimation { to: 1; duration: 500 } }
                        }
                    }
                }

                Repeater {
                    model: 7
                    Item {
                        id: line
                        required property int index
                        readonly property var app: win.hits[index] ?? null
                        readonly property bool on: index === win.sel
                        readonly property string target: app ? app.name + (app.genericName ? "  // " + app.genericName : "") : ""
                        visible: target !== "" || shown.trim() !== ""
                        width: col.width
                        height: 22

                        property string from: ""
                        property real k: 1
                        onTargetChanged: { from = shown; k = 0; morph.restart() }
                        NumberAnimation { id: morph; target: line; property: "k"; to: 1; duration: Theme.ms(220 + line.index * 35) }
                        readonly property string shown: Decode.frame(from, target, k, true)

                        Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.accent, line.on && line.app ? 0.14 : 0) }
                        Row {
                            x: 6
                            height: parent.height
                            spacing: 8
                            DecodeText { text: line.on ? "›" : String(line.index + 1); color: line.on ? Theme.accent : Theme.alpha(Theme.fg, 0.3); height: parent.height; visible: !!line.app }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: col.width - 34
                                elide: Text.ElideRight
                                textFormat: Text.StyledText
                                text: {
                                    const cut = line.app ? line.app.name.length : line.shown.length
                                    const esc = t => t.replace(/&/g, "&amp;").replace(/</g, "&lt;")
                                    return esc(line.shown.slice(0, cut)) + "<font color='" + Theme.dim + "'>" + esc(line.shown.slice(cut)) + "</font>"
                                }
                                font.family: Theme.font
                                font.pixelSize: 13
                                color: line.on ? Theme.fg : Theme.alpha(Theme.fg, 0.8)
                            }
                        }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: if (line.app) win.sel = line.index; onClicked: if (line.app) win.launch() }
                    }
                }
                DecodeText { visible: field.text !== "" && !win.hits.length; text: "command not found"; color: Theme.alpha(Theme.fg, 0.35); height: 22 }
            }
        }
    }
}
