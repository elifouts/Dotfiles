import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../common"
import "../ui"
import "../ui/decode.js" as Decode

// tap super, a little terminal drops out of the bar
PanelWindow {
    id: win

    signal done()
    screen: Ui.target
    anchors.top: true
    // from the very top edge so it slides over the bar instead of out from under it
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Math.min(620, (screen?.width ?? 800) - 40)
    implicitHeight: 300 + rest
    mask: Region { item: frame }
    color: "transparent"
    WlrLayershell.namespace: "space-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property int sel: 0
    // where it settles, just under the bar
    readonly property real rest: 42
    property real t: 0
    Component.onCompleted: grow.start()
    function close() { if (!shut.running) { grow.stop(); shut.start() } }
    NumberAnimation { id: grow; target: win; property: "t"; to: 1; duration: Theme.open; easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: shut
        NumberAnimation { target: win; property: "t"; to: 0; duration: Theme.quick; easing.type: Easing.InCubic }
        ScriptAction { script: win.done() }
    }

    HyprlandFocusGrab { active: true; windows: [win]; onCleared: win.close() }

    // subsequence match, runs and word starts score more
    function score(q, s) {
        s = (s || "").toLowerCase()
        let i = 0, pts = 0, run = 0
        for (let j = 0; j < s.length && i < q.length; j++) {
            if (s[j] !== q[i]) { run = 0; continue }
            run++
            pts += run * 2 + (j === 0 || " -_.".includes(s[j - 1]) ? 6 : 0)
            i++
        }
        return i === q.length ? pts - s.length * 0.05 : -1
    }
    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)
    readonly property var hits: {
        const q = field.text.trim().toLowerCase()
        if (!q) return []
        return apps.map(a => [a, Math.max(score(q, a.name) * 1.5, score(q, a.genericName), score(q, (a.keywords || []).join(" ")))])
            .filter(x => x[1] >= 0).sort((a, b) => b[1] - a[1]).slice(0, 7).map(x => x[0])
    }
    onHitsChanged: sel = 0

    function launch() {
        const a = hits[sel]
        if (a) a.execute()
        close()
    }

    // falls in from off the top of the screen and goes back up there
    Item {
        id: drop
        width: parent.width
        height: frame.height
        y: -height + (win.rest + height) * win.t

        Rectangle {
            id: frame
            width: parent.width
            height: col.height + 26
            color: Theme.alpha(Theme.bg, 0.8)
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
                    Hud { text: "~/run"; color: Theme.accent; font.capitalization: Font.MixedCase; height: 22 }
                    Hud { text: "$"; color: Theme.dim; height: 22 }
                    TextInput {
                        id: field
                        // the block below is the cursor, this hides the thin one qt draws too
                        cursorDelegate: Item {}
                        width: col.width - 70
                        height: 22
                        verticalAlignment: TextInput.AlignVCenter
                        focus: true
                        font.family: Theme.font
                        font.pixelSize: 14
                        color: Theme.fg
                        cursorVisible: false
                        selectionColor: Theme.alpha(Theme.accent, 0.4)
                        Keys.onEscapePressed: win.close()
                        Keys.onReturnPressed: win.launch()
                        Keys.onEnterPressed: win.launch()
                        Keys.onDownPressed: win.sel = Math.min(win.hits.length - 1, win.sel + 1)
                        Keys.onUpPressed: win.sel = Math.max(0, win.sel - 1)
                        Keys.onTabPressed: win.sel = (win.sel + 1) % Math.max(1, win.hits.length)
                        // a block cursor that blinks, only while this is open
                        Rectangle {
                            x: field.cursorRectangle.x
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8; height: 15
                            color: Theme.accent
                            SequentialAnimation on opacity { loops: Animation.Infinite; NumberAnimation { to: 0; duration: 500 } NumberAnimation { to: 1; duration: 500 } }
                        }
                    }
                }

                // fixed rows that decode from what they said into what they say now, so typing ripples instead of restarting
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
                        NumberAnimation { id: morph; target: line; property: "k"; to: 1; duration: 220 + line.index * 35 }
                        readonly property string shown: Decode.frame(from, target, k, true)

                        Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.accent, line.on && line.app ? 0.14 : 0) }
                        Row {
                            x: 6
                            height: parent.height
                            spacing: 8
                            Hud { text: line.on ? "›" : String(line.index + 1); color: line.on ? Theme.accent : Theme.alpha(Theme.fg, 0.3); height: parent.height; visible: !!line.app }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
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
                Hud { visible: field.text !== "" && !win.hits.length; text: "command not found"; color: Theme.alpha(Theme.fg, 0.35); height: 22 }
            }
        }
    }
}
