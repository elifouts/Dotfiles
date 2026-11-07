import QtQuick
import Quickshell
import "../../../shared"
import "../../common"

Column {
    id: pw
    spacing: 6
    property string armed: ""
    Component.onCompleted: BrightnessShared.probe()
    Timer { id: disarm; interval: 2500; onTriggered: pw.armed = "" }

    Controls.Title { glyph: "󰐥"; text: "power" }
    Controls.Line {
        visible: PowerShared.hasBattery
        glyph: PowerShared.charging ? "󰂄" : "󰁹"
        text: PowerShared.charging ? "charging" : PowerShared.full ? "full" : "battery"
        value: Math.round(PowerShared.charge * 100) + "%"
        lit: PowerShared.charging
    }
    Controls.Slide { visible: BrightnessShared.has; glyph: "󰃟"; value: BrightnessShared.value; onMoved: v => BrightnessShared.set(v) }
    Item { width: 1; height: 4 }
    Row {
        id: tiles
        width: parent.width
        spacing: 4
        readonly property real w: (width - spacing * 4 - 12) / 5
        Repeater {
            model: [["lock", "󰌾"], ["suspend", "󰒲"], ["logout", "󰍃"], ["reboot", "󰜉"], ["poweroff", "󰐥"]]
            Rectangle {
                id: tile
                required property var modelData
                required property int index
                readonly property bool armedNow: pw.armed === modelData[0]
                readonly property color ink: armedNow ? Theme.warn : ma.containsMouse ? Theme.accent : Theme.fg
                width: tiles.w + (index === 2 ? 12 : 0)
                height: 50
                color: "transparent"
                Rectangle {
                    x: tile.index === 2 ? 12 : 0
                    width: tiles.w
                    height: parent.height
                    color: Theme.alpha(tile.armedNow ? Theme.warn : Theme.accent, tile.armedNow ? 0.14 : ma.containsMouse ? 0.08 : 0)
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    Column {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData[1]
                            font.family: Theme.font
                            font.pixelSize: 16
                            color: tile.ink
                            scale: ma.pressed ? 0.85 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.ms(120); easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: Theme.fast } }
                        }
                        DecodeText { anchors.horizontalCenter: parent.horizontalCenter; font.pixelSize: 9; text: tile.armedNow ? "again" : tile.modelData[0]; color: tile.armedNow ? Theme.warn : Theme.dim }
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        height: 2
                        color: Theme.warn
                        width: tile.armedNow ? parent.width : 0
                        NumberAnimation on width { running: tile.armedNow; from: tiles.w; to: 0; duration: disarm.interval }
                    }
                    HoverShared {
                        id: ma
                        anchors.fill: parent
                        onClicked: {
                            if (PowerShared.confirm(tile.modelData[0]) && !tile.armedNow) { pw.armed = tile.modelData[0]; return disarm.restart() }
                            Ui.panel = ""
                            PowerShared.act(tile.modelData[0])
                        }
                    }
                }
            }
        }
    }
}
