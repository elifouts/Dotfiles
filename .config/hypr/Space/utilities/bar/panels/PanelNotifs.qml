import QtQuick
import Quickshell
import "../../common"

Column {
    spacing: 6
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Kit.Title {
        glyph: Notifs.dnd ? "󰂛" : "󰂚"
        text: Notifs.count ? Notifs.count + " notices" : "all clear"
        Kit.Toggle { text: "dnd"; on: Notifs.dnd; onFlip: Notifs.dnd = !Notifs.dnd }
        Button { visible: Notifs.count > 0; label: "clear"; onPressed: Notifs.clearAll() }
    }
    Repeater {
        model: Notifs.notifs.slice(0, 8)
        Item {
            id: row
            required property var modelData
            width: parent.width
            height: col.height + 10
            Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.accent, ma.containsMouse ? 0.08 : 0) }
            Rectangle { width: 2; height: parent.height; color: Theme.alpha(Theme.accent, 0.6) }
            Column {
                id: col
                x: 10
                y: 5
                width: parent.width - 34
                Item {
                    width: parent.width
                    height: 14
                    Hud { text: row.modelData.appName || "notice"; color: Theme.accent; font.pixelSize: 10 }
                    Hud { anchors.right: parent.right; text: Notifs.ago(row.modelData, clock.date); font.pixelSize: 10 }
                }
                Hud { caps: false; width: parent.width; text: row.modelData.summary; elide: Text.ElideRight; font.pixelSize: 12; color: Theme.fg }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: row.modelData.body
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.family: Theme.font
                    font.pixelSize: 11
                    color: Theme.dim
                }
            }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: row.modelData.dismiss() }
        }
    }
}
