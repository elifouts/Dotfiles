import QtQuick
import "../common"

Item {
    id: chip
    property string glyph
    property string text
    property string panel
    property string tab: ""
    property bool hot: false
    property bool show: true
    property bool decode: true
    property real room: 0
    signal wheel(int dir)
    readonly property var wing: parent?.parent
    readonly property bool open: Ui.panel === panel && Ui.panelScreen === wing?.scr && (tab === "" || Ui.tab === tab)

    property real reveal: show ? 1 : 0
    Behavior on reveal { SettleShared { duration: Theme.ms(260) } }
    visible: reveal > 0.001
    opacity: reveal
    property real natW: row.width + 14 + room
    Behavior on natW { SettleShared { id: resize; duration: Theme.open } }
    clip: reveal < 0.999 || resize.running
    width: natW * reveal
    height: 28

    function openIt() { Ui.openPanel(panel, wing.scr, tab) }
    onOpenChanged: if (wing) wing.openCount += open ? 1 : -1

    Row {
        id: row
        height: parent.height
        spacing: 6
        Text {
            id: g
            visible: chip.glyph !== ""
            text: chip.glyph
            font.family: Theme.font
            font.pixelSize: 13
            color: chip.hot ? Theme.warn : chip.open ? Theme.accent : Theme.alpha(Theme.accent, 0.75)
            anchors.verticalCenter: parent.verticalCenter
            scale: area.pressed ? 0.85 : area.containsMouse ? 1.15 : 1
            Behavior on scale { NumberAnimation { duration: Theme.ms(area.pressed ? 70 : 220); easing.type: area.pressed ? Easing.OutQuad : Easing.OutBack } }
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            SequentialAnimation on opacity {
                running: chip.hot && chip.visible
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
                onRunningChanged: if (!running) g.opacity = 1
            }
        }
        Hud {
            visible: chip.text !== ""
            decode: chip.decode
            text: chip.text
            height: parent.height
            color: chip.open || area.containsMouse ? Theme.fg : Theme.alpha(Theme.fg, 0.7)
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
    }
    Rectangle {
        anchors.bottom: parent.bottom
        height: 2
        width: chip.open ? row.width + chip.room : 0
        x: (row.width + chip.room - width) / 2
        color: Theme.accent
        Behavior on width { SettleShared { duration: Theme.ms(200) } }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -5
        hoverEnabled: true
        onEntered: if (chip.panel !== "scan" && !chip.open) chip.openIt()
        onClicked: if (chip.panel === "scan" || !chip.open) chip.openIt()
        onWheel: w => chip.wheel(w.angleDelta.y > 0 ? 1 : -1)
    }
}
