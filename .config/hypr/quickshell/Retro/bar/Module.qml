import QtQuick
import "../../shared"
import "../common"

Item {
    id: mod
    property string glyph
    property string label
    property string text
    property string panel
    property string tab: ""
    property bool hot: false
    property bool show: true
    property bool type: true
    property real room: 0
    signal wheel(int dir)
    readonly property var pill: { let p = parent; while (p && !("framed" in p)) p = p.parent; return p }
    readonly property bool open: Ui.owner === mod && Ui.panel === panel && Ui.panelScreen === pill?.scr
    readonly property bool hovered: hov.hovered
    HoverHandler { id: hov; onHoveredChanged: if (hovered && mod.panel && mod.panel !== "home") mod.openIt() }

    property bool cut: false
    readonly property real natural: show ? row.width + room + 8 : 0
    visible: show && !cut
    width: visible ? natural : 0
    height: Theme.bar

    function openIt() {
        if (panel === "home") return Ui.request("home")
        if (open) return
        Ui.ax = mapToItem(null, width / 2, 0).x
        Ui.owner = mod
        Ui.panelScreen = pill.scr
        Ui.tab = tab
        Ui.panel = panel
    }

    Blink { id: blink; running: mod.hot && mod.visible }
    readonly property color ink: mod.open ? Theme.bg : mod.hot ? (blink.on ? Theme.warn : Theme.dim) : Theme.fg

    Rectangle { anchors.fill: parent; anchors.topMargin: 3; anchors.bottomMargin: 3; color: mod.open ? Theme.accent : mod.hovered ? Theme.low : "transparent" }
    Row {
        id: row
        x: 4
        height: parent.height
        spacing: 6
        Text { visible: mod.glyph !== ""; text: mod.glyph; font.family: Theme.font; font.pixelSize: Theme.size; color: mod.open ? Theme.bg : Theme.accent; anchors.verticalCenter: parent.verticalCenter }
        Type { visible: mod.label !== ""; text: mod.label; height: parent.height; color: mod.open ? Theme.bg : Theme.dim }
        Type { visible: mod.text !== ""; type: mod.type; text: mod.text; height: parent.height; color: mod.ink }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: mod.openIt()
        onWheel: w => mod.wheel(w.angleDelta.y > 0 ? 1 : -1)
    }
}
