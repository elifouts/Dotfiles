import QtQuick
import "../../shared"
import "../common"

Item {
    id: mod
    property string glyph
    property string text
    property string panel
    property string tab: ""
    property bool hot: false
    property bool show: true
    property bool decode: true
    property real room: 0
    signal wheel(int dir)
    readonly property var pill: { let p = parent; while (p && !("openCount" in p)) p = p.parent; return p }
    readonly property bool open: Ui.panel === panel && Ui.panelScreen === pill?.scr && (tab === "" || Ui.tab === tab)

    property real reveal: show ? 1 : 0
    Behavior on reveal { SettleShared { duration: Theme.ms(260) } }
    visible: reveal > 0.001
    opacity: reveal
    property real natW: row.width + room
    Behavior on natW { SettleShared { id: resize; duration: Theme.open } }
    clip: reveal < 0.999 || resize.running
    width: natW * reveal
    height: 28

    function openIt() { Ui.openPanel(panel, pill.scr, tab) }
    onOpenChanged: if (pill) pill.openCount += open ? 1 : -1

    Row {
        id: row
        height: parent.height
        spacing: 6
        Text {
            id: g
            visible: mod.glyph !== ""
            text: mod.glyph
            font.family: Theme.font
            font.pixelSize: 13
            color: mod.hot ? Theme.warn : mod.open ? Theme.accent : Theme.alpha(Theme.accent, 0.75)
            anchors.verticalCenter: parent.verticalCenter
            scale: area.pressed ? 0.85 : area.containsMouse ? 1.15 : 1
            Behavior on scale { NumberAnimation { duration: Theme.ms(area.pressed ? 70 : 220); easing.type: area.pressed ? Easing.OutQuad : Easing.OutBack } }
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            SequentialAnimation on opacity {
                running: mod.hot && mod.visible
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
                onRunningChanged: if (!running) g.opacity = 1
            }
        }
        DecodeText {
            visible: mod.text !== ""
            decode: mod.decode
            text: mod.text
            height: parent.height
            color: mod.open || area.containsMouse ? Theme.fg : Theme.alpha(Theme.fg, 0.7)
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
    }
    Rectangle {
        anchors.bottom: parent.bottom
        height: 2
        width: mod.open ? row.width + mod.room : 0
        x: (row.width + mod.room - width) / 2
        color: Theme.accent
        Behavior on width { SettleShared { duration: Theme.ms(200) } }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -5
        hoverEnabled: true
        onEntered: if (mod.panel !== "home" && !mod.open) mod.openIt()
        onClicked: if (mod.panel === "home" || !mod.open) mod.openIt()
        onWheel: w => mod.wheel(w.angleDelta.y > 0 ? 1 : -1)
    }
}
