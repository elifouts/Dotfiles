import QtQuick
import "../common"
import "../bar"

Rectangle {
    id: strip

    required property var model
    readonly property var cur: model.picked >= 0 ? model.items[model.picked] : null

    width: row.width + 32
    height: 44
    color: Theme.glass
    border.width: 1
    border.color: Theme.alpha(Theme.accent, 0.35)

    transform: Translate { id: lift; y: 60 }
    Component.onCompleted: rise.start()
    SettleShared { id: rise; target: lift; property: "y"; to: 0; duration: Theme.slow }

    component Chip: Hud {
        property bool on: false
        signal hit()
        height: 44
        leftPadding: 7
        rightPadding: 7
        color: on ? Theme.accent : mouse.containsMouse ? Theme.fg : Theme.dim
        MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: parent.hit() }
    }
    component Sep: Rectangle { width: 1; height: 18; anchors.verticalCenter: parent.verticalCenter; color: Theme.faint }

    Row {
        id: row
        anchors.centerIn: parent

        Hud { text: "add"; height: 44; rightPadding: 6; color: Theme.alpha(Theme.fg, 0.3) }
        Repeater {
            model: ["clock", "stats", "media", "viz", "note", "todo"]
            Chip { required property string modelData; text: "+" + modelData; onHit: strip.model.add(modelData) }
        }

        Sep { visible: !!strip.cur }
        Repeater {
            model: strip.cur ? ["plain", "frame", "glow"] : []
            Chip { required property string modelData; text: modelData; on: strip.cur.style === modelData; onHit: strip.model.change(strip.model.picked, { style: modelData }) }
        }
        Sep { visible: !!strip.cur }
        Repeater {
            model: strip.cur ? [["left", "←"], ["center", "↔"], ["right", "→"]] : []
            Chip { required property var modelData; text: modelData[1]; on: (strip.cur.align ?? "left") === modelData[0]; onHit: strip.model.change(strip.model.picked, { align: modelData[0] }) }
        }
        Sep { visible: !!strip.cur }
        Item {
            visible: !!strip.cur
            width: 110
            height: 44
            Rectangle { id: track; anchors.verticalCenter: parent.verticalCenter; x: 8; width: 94; height: 1; color: Theme.faint }
            Rectangle {
                width: 7; height: 7; radius: 4
                anchors.verticalCenter: parent.verticalCenter
                x: track.x + track.width * (((strip.cur?.s ?? 1) - 0.5) / 2.5) - 3
                color: Theme.accent
            }
            MouseArea {
                anchors.fill: parent
                function set(mx) { strip.model.change(strip.model.picked, { s: 0.5 + 2.5 * Math.max(0, Math.min(1, (mx - track.x) / track.width)) }) }
                onPressed: m => set(m.x)
                onPositionChanged: m => { if (pressed) set(m.x) }
            }
        }
        Chip { visible: !!strip.cur; text: "del"; color: Theme.warn; onHit: strip.model.remove(strip.model.picked) }

        Sep {}
        Chip { text: "done"; on: true; onHit: Ui.editing = "" }
    }
}
