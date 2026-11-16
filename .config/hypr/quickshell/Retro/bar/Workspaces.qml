import QtQuick
import Quickshell.Hyprland
import "../../shared"
import "../common"

Row {
    id: ws
    readonly property int focused: Hyprland.focusedWorkspace?.id ?? 1
    readonly property var onScreen: Hyprland.monitors.values.map(m => m.activeWorkspace?.id ?? -1)
    function count(id) { return HyprShared.workspaces.find(w => w.id === id)?.toplevels.values.length ?? 0 }
    function go(id) { if (id !== focused) Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })") }
    height: Theme.bar
    spacing: 2

    Repeater {
        model: HyprShared.workspaceIds
        Item {
            id: cell
            required property int modelData
            readonly property bool lit: modelData === ws.focused
            readonly property bool shown: ws.onScreen.includes(modelData)
            readonly property int n: ws.count(modelData)
            width: label.implicitWidth + 10
            height: ws.height
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 3
                anchors.bottomMargin: 3
                color: cell.lit ? Theme.accent : area.containsMouse ? Theme.low : "transparent"
                border.width: cell.shown && !cell.lit ? 1 : 0
                border.color: Theme.line
            }
            Text {
                id: label
                anchors.centerIn: parent
                text: cell.modelData + (cell.n > 1 ? "·" + cell.n : "")
                font.family: Theme.font
                font.pixelSize: Theme.size
                color: cell.lit ? Theme.bg : cell.n ? Theme.fg : Theme.dim
            }
            MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: ws.go(cell.modelData) }
        }
    }
    WheelHandler {
        onWheel: e => {
            const ids = HyprShared.workspaceIds, i = ids.indexOf(ws.focused)
            ws.go(ids[Math.max(0, Math.min(ids.length - 1, i + (e.angleDelta.y > 0 ? -1 : 1)))])
        }
    }
}
