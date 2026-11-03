import QtQuick
import "../common"
import "../ui"

// a readout that opens its panel. collapses to nothing when show goes false
Item {
    id: chip
    property string glyph
    property string text
    property string panel
    // media panel tab it opens on, the timer chip uses it
    property string tab: ""
    property bool hot: false
    property bool show: true
    readonly property var wing: parent?.parent
    readonly property bool open: Ui.panel === panel && Ui.panelScreen === wing?.scr && (tab === "" || Ui.tab === tab)

    property real reveal: show ? 1 : 0
    Behavior on reveal { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    visible: reveal > 0.001
    opacity: reveal
    // eases to the new size when the text changes, the wing follows along
    property real natW: row.width + 14
    Behavior on natW { NumberAnimation { id: resize; duration: Theme.open; easing.type: Easing.OutCubic } }
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
            Behavior on scale { NumberAnimation { duration: area.pressed ? 70 : 220; easing.type: area.pressed ? Easing.OutQuad : Easing.OutBack } }
            Behavior on color { ColorAnimation { duration: 140 } }
            SequentialAnimation on opacity {
                // only while it's on screen. the hidden timer chip is hot whenever no timer runs, and any looping
                // animation, seen or not, makes qt redraw every window (wallpaper included) at full refresh
                running: chip.hot && chip.visible
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
                onRunningChanged: if (!running) g.opacity = 1
            }
        }
        Hud {
            visible: chip.text !== ""
            text: chip.text
            height: parent.height
            color: chip.open || area.containsMouse ? Theme.fg : Theme.alpha(Theme.fg, 0.7)
            Behavior on color { ColorAnimation { duration: 140 } }
        }
    }
    Rectangle {
        anchors.bottom: parent.bottom
        height: 2
        width: chip.open ? row.width : 0
        x: (row.width - width) / 2
        color: Theme.accent
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -5
        hoverEnabled: true
        onEntered: if (chip.panel !== "scan" && !chip.open) chip.openIt()
        onClicked: if (chip.panel === "scan" || !chip.open) chip.openIt()
    }
}
