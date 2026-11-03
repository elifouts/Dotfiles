import QtQuick
import Quickshell
import "../common"
import "../ui"

// battery, brightness and session, the scary ones want two clicks
Column {
    id: pw
    spacing: 6
    property string armed: ""
    Component.onCompleted: Brightness.probe()
    Timer { id: disarm; interval: 2500; onTriggered: pw.armed = "" }

    Kit.Title { glyph: "󰐥"; text: "power" }
    Kit.Line {
        visible: Power.hasBattery
        glyph: Power.charging ? "󰂄" : "󰁹"
        text: Power.charging ? "charging" : Power.full ? "full" : "battery"
        value: Math.round(Power.charge * 100) + "%"
        lit: Power.charging
    }
    Kit.Slide { visible: Brightness.has; glyph: "󰃟"; value: Brightness.value; onMoved: v => Brightness.set(v) }
    Item { width: 1; height: 4 }
    // lock and sleep on the left, the ones that end your session on the right past a gap
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
                    Behavior on color { ColorAnimation { duration: 140 } }
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
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                        Hud { anchors.horizontalCenter: parent.horizontalCenter; font.pixelSize: 9; text: tile.armedNow ? "again" : tile.modelData[0]; color: tile.armedNow ? Theme.warn : Theme.dim }
                    }
                    // shrinks while it waits for the second click
                    Rectangle {
                        anchors.bottom: parent.bottom
                        height: 2
                        color: Theme.warn
                        width: tile.armedNow ? parent.width : 0
                        NumberAnimation on width { running: tile.armedNow; from: tiles.w; to: 0; duration: disarm.interval }
                    }
                    Hover {
                        id: ma
                        anchors.fill: parent
                        onClicked: {
                            if (Power.confirm(tile.modelData[0]) && !tile.armedNow) { pw.armed = tile.modelData[0]; return disarm.restart() }
                            Ui.panel = ""
                            Power.act(tile.modelData[0])
                        }
                    }
                }
            }
        }
    }
}
