import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../shared"
import "../common"

PanelWindow {
    id: win

    signal done()
    screen: Ui.target
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region { item: frame }
    WlrLayershell.namespace: "retro-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.touring ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
    HyprlandFocusGrab { active: !Ui.touring; windows: [win]; onCleared: win.close() }

    readonly property string cache: HyprShared.home + "/.cache/launcher/apps"
    property var paths: ({})
    property var uses: ({})
    property var cmds: []
    property bool cmd: false
    property int sel: 0
    onCmdChanged: { sel = 0; if (cmd && !cmds.length) scan.running = true }

    Process {
        running: true
        command: ["python3", HyprShared.util + "/launcher.py", "apps"]
        stdout: StdioCollector { onStreamFinished: { try { win.paths = JSON.parse(text).paths } catch (e) {} } }
    }
    Process {
        id: scan
        command: ["python3", HyprShared.util + "/launcher.py", "commands"]
        stdout: StdioCollector { onStreamFinished: { try { win.cmds = JSON.parse(text).map(e => ({ name: e.n, genericName: e.k === "bin" ? "" : e.d })) } catch (e) {} } }
    }
    FileView {
        path: win.cache
        printErrors: false
        onLoaded: {
            const out = {}
            for (const l of text().split("\n")) { const m = l.match(/^(\d+) (.+)$/); if (m) out[m[2]] = parseInt(m[1]) }
            win.uses = out
        }
    }

    property real t: 0
    Component.onCompleted: grow.start()
    function close() { if (!shut.running) { grow.stop(); shut.start() } }
    NumberAnimation { id: grow; target: win; property: "t"; to: 1; duration: Theme.open }
    SequentialAnimation {
        id: shut
        NumberAnimation { target: win; property: "t"; to: 0; duration: Theme.ms(90) }
        ScriptAction { script: win.done() }
    }

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
    function used(a) { return uses[paths[a.id]] || 0 }
    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)
    readonly property int rows: 9
    readonly property var hits: {
        const line = field.text.trim(), q = line.toLowerCase()
        if (!q) return cmd ? [] : apps.slice().sort((a, b) => used(b) - used(a) || a.name.localeCompare(b.name)).slice(0, rows)
        const key = cmd ? q.split(/\s+/)[0] : q
        const found = (cmd ? cmds : apps).map(a => [a, Math.max(score(key, a.name) * 1.5, score(key, a.genericName), score(key, (a.keywords || []).join(" "))) + (cmd ? 0 : Math.min(20, used(a)))])
            .filter(x => x[1] >= 0).sort((a, b) => b[1] - a[1]).map(x => x[0])
        if (!cmd) return found.slice(0, rows)
        const typed = { name: line, genericName: "run as typed" }
        return /\s/.test(q) || found[0]?.name.toLowerCase() !== q ? [typed, ...found.slice(0, rows - 1)] : found.slice(0, rows)
    }
    onHitsChanged: sel = 0

    function launch(i, background) {
        const a = hits[i]
        if (a?.execute) {
            if (a.runInTerminal) Quickshell.execDetached(["kitty", "-e"].concat(a.command))
            else a.execute()
            if (paths[a.id]) Quickshell.execDetached(["python3", HyprShared.util + "/launcher.py", "bump", cache, paths[a.id]])
        } else if (a) Quickshell.execDetached((background ? [] : ["kitty", "--hold", "env", "NOFETCH=1"]).concat(["bash", "-ic", a.name]))
        close()
    }

    Box {
        id: frame
        anchors.centerIn: parent
        width: Math.min(760, win.width - 80)
        height: col.implicitHeight + 36
        double: true
        opacity: win.t
        transform: Scale { origin.x: frame.width / 2; origin.y: frame.height / 2; yScale: 0.04 + 0.96 * Math.min(1, win.t * 1.4); xScale: Math.min(1, 0.6 + win.t) }

        Column {
            id: col
            x: 22
            y: 16
            width: parent.width - 44
            spacing: 4

            Item {
                width: parent.width
                height: 22
                Type { anchors.horizontalCenter: parent.horizontalCenter; height: parent.height; text: win.cmd ? "command" : "main"; color: Theme.accent }
                Type { anchors.right: parent.right; height: parent.height; text: win.cmd ? "c1" : "a1"; color: Theme.dim }
            }
            Type { anchors.horizontalCenter: parent.horizontalCenter; caps: false; text: (win.cmd ? "Shell commands" : "Program menu") + "  ·  " + Quickshell.env("USER") + "@" + Ui.host; color: Theme.fg }
            Item { width: 1; height: 6 }
            Type { caps: false; text: win.cmd ? "Run one of the following:" : "Select one of the following:"; color: Theme.fg }
            Item { width: 1; height: 4 }

            Repeater {
                model: win.rows
                Item {
                    id: line
                    required property int index
                    readonly property var app: win.hits[index] ?? null
                    readonly property bool on: index === win.sel && !!app
                    width: col.width
                    height: 22
                    Rectangle { x: 18; width: parent.width - 18; height: parent.height; color: line.on ? Theme.accent : hover.containsMouse && line.app ? Theme.low : "transparent" }
                    Type {
                        x: 24
                        width: parent.width - 30
                        height: parent.height
                        caps: false
                        elide: Text.ElideRight
                        text: line.app ? (line.index + 1) + ". " + line.app.name + (line.app.genericName ? "  — " + line.app.genericName : "") : ""
                        color: line.on ? Theme.bg : Theme.fg
                    }
                    MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; onEntered: if (line.app) win.sel = line.index; onClicked: if (line.app) win.launch(line.index) }
                }
            }
            Type { visible: field.text !== "" && !win.hits.length; caps: false; text: "SYS-0404  No match for that name"; color: Theme.warn; height: 22 }

            Item { width: 1; height: 8 }
            Row {
                spacing: 34
                Repeater {
                    model: ["Tab-" + (win.cmd ? "Programs" : "Commands"), "Esc-End", "⇧Enter-Background"]
                    Type { required property string modelData; caps: false; text: modelData; color: Theme.dim; visible: modelData[0] !== "⇧" || win.cmd }
                }
            }
            Type { caps: false; text: "Ready for option number or " + (win.cmd ? "command" : "program name"); color: Theme.fg }
            Row {
                spacing: 8
                height: 24
                Text { text: ">"; font.family: Theme.font; font.pixelSize: Theme.size + 2; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                TextInput {
                    id: field
                    width: col.width - 40
                    height: 24
                    verticalAlignment: TextInput.AlignVCenter
                    focus: true
                    font.family: Theme.font
                    font.pixelSize: Theme.size + 2
                    color: Theme.fg
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.bg
                    cursorDelegate: Rectangle { width: 9; color: Theme.accent; visible: blink.on }
                    onTextChanged: blink.restart()
                    Blink { id: blink; running: true }
                    Keys.onEscapePressed: win.close()
                    Keys.onReturnPressed: e => win.launch(win.sel, e.modifiers & Qt.ShiftModifier)
                    Keys.onEnterPressed: e => win.launch(win.sel, e.modifiers & Qt.ShiftModifier)
                    Keys.onDownPressed: win.sel = Math.min(win.hits.length - 1, win.sel + 1)
                    Keys.onUpPressed: win.sel = Math.max(0, win.sel - 1)
                    Keys.onTabPressed: win.cmd = !win.cmd
                    Keys.onPressed: e => {
                        const n = parseInt(e.text)
                        if (!field.text && n >= 1 && n <= win.hits.length) { e.accepted = true; win.launch(n - 1) }
                    }
                }
            }
            Rectangle { width: parent.width; height: 1; color: Theme.low }
            Item {
                width: parent.width
                height: 20
                Type { height: parent.height; caps: false; text: "SYS-" + String(win.apps.length).padStart(4, "0") + "  " + win.apps.length + " programs indexed"; color: Theme.dim; font.pixelSize: Theme.size - 2 }
                Type { anchors.right: parent.right; height: parent.height; type: false; text: (win.sel + 1) + "/" + win.hits.length; color: Theme.dim; font.pixelSize: Theme.size - 2 }
            }
        }
    }
}
