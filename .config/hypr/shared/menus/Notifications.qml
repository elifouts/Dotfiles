import QtQuick
import Quickshell
import "../../common"

Column {
    spacing: 8

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Header {
        title: "Notifications"
        Round { glyph: ""; visible: Notifs.count > 0; onClicked: Notifs.clearAll() }
    }
    Toggle { label: "Do not disturb"; checked: Notifs.dnd; onToggled: Notifs.dnd = checked }
    Say { visible: Notifs.count === 0; text: "All clear"; font.pixelSize: 12; color: Theme.dim }

    Repeater {
        model: Notifs.notifs.slice(0, 8)

        Tile {
            id: row
            required property var modelData
            width: parent.width
            height: col.implicitHeight + 16

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Theme.alpha(Theme.accent, area.containsMouse ? 0.08 : 0)
            }
            Column {
                id: col
                x: 10
                y: 8
                width: parent.width - 20
                spacing: 2
                Item {
                    width: parent.width
                    height: 14
                    Say { text: row.modelData.appName || "Notice"; font.pixelSize: 10; font.capitalization: Font.AllUppercase; color: Theme.accent }
                    Say { anchors.right: parent.right; text: Notifs.ago(row.modelData, clock.date); font.pixelSize: 10; color: Theme.dim }
                }
                Say { width: parent.width; text: row.modelData.summary; elide: Text.ElideRight; font.pixelSize: 12; color: Theme.fg }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: row.modelData.body
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.family: Theme.sans
                    font.pixelSize: 11
                    color: Theme.dim
                }
            }
            Hover { id: area; anchors.fill: parent; onClicked: row.modelData.dismiss() }
        }
    }
}
