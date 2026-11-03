import QtQuick
import Quickshell
import "../../common"

// shares waybar's history in ~/.cache/colorpicker/colors
Item {
    id: page

    signal pick()
    signal copy(string color)

    Watched {
        id: history
        path: Quickshell.env("HOME") + "/.cache/colorpicker/colors"
    }
    readonly property var colors: history.text().split("\n").map(s => s.trim()).filter(s => /^#[0-9a-fA-F]{6}$/.test(s))
    readonly property string last: colors.length > 0 ? colors[0] : ""
    property string copied: ""
    Timer { id: unmark; interval: 1400; onTriggered: page.copied = "" }

    function copyColor(c) {
        copy(c)
        copied = c
        unmark.restart()
    }

    function rgb(c) {
        const v = parseInt(c.slice(1), 16)
        return [(v >> 16) & 255, (v >> 8) & 255, v & 255].join("  ")
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 18

        Rectangle {
            width: 118
            height: 118
            radius: Math.min(Theme.rounding, 14)
            color: page.last !== "" ? page.last : Theme.alpha(Theme.fg, 0.06)
            border.width: 1
            border.color: Theme.alpha(Theme.fg, 0.1)

            Label {
                anchors.centerIn: parent
                visible: page.last === ""
                text: "󰈊"
                font.pixelSize: 26
                color: Theme.dim
            }
            MouseArea {
                anchors.fill: parent
                enabled: page.last !== ""
                cursorShape: Qt.PointingHandCursor
                onClicked: page.copyColor(page.last)
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Label {
                text: page.last !== "" ? page.last.toUpperCase() : "No colors yet"
                font.pixelSize: 22
                font.bold: page.last !== ""
                color: Theme.bright
            }
            Label {
                text: page.copied !== "" ? "Copied " + page.copied.toUpperCase()
                    : page.last !== "" ? "RGB  " + page.rgb(page.last) : "Pick one from anywhere on screen"
                font.pixelSize: 11
                color: page.copied !== "" ? Theme.ok : Theme.dim
            }

            Item { width: 1; height: 6 }

            Button {
                primary: true
                label: "󰈊  Pick"
                onPressed: page.pick()
            }

            Item { width: 1; height: 4 }

            Row {
                spacing: 7

                Repeater {
                    model: page.colors.slice(1, 9)

                    Rectangle {
                        required property string modelData
                        width: 22
                        height: 22
                        radius: 11
                        color: modelData
                        border.width: 1
                        border.color: Theme.alpha(Theme.fg, swatchArea.containsMouse ? 0.5 : 0.1)
                        scale: swatchArea.containsMouse ? 1.12 : 1
                        Behavior on scale { Settle { duration: Theme.fast } }
                        MouseArea { id: swatchArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.copyColor(parent.modelData) }
                    }
                }
            }
        }
    }

}
