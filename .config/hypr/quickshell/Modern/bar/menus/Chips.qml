import QtQuick
import "../../../shared"
import "../../common"

Flow {
    id: chips

    property var options: []
    property string value: ""
    signal picked(string v)

    width: parent ? parent.width : 0
    spacing: 6

    Repeater {
        model: chips.options

        Rectangle {
            id: chip
            required property var modelData
            readonly property bool on: chips.value === modelData[0]
            width: label.implicitWidth + 22
            height: 26
            radius: Math.min(Theme.rounding, height / 2)
            color: on ? Theme.soft(Theme.accent, chipArea.containsMouse)
                : Theme.alpha(Theme.fg, chipArea.containsMouse ? 0.14 : 0.07)
            Behavior on color { ColorAnimation { duration: Theme.ms(140) } }

            LabelShared {
                id: label
                anchors.centerIn: parent
                text: chip.modelData[1]
                font.pixelSize: 11
                color: chip.on ? Theme.ink : Theme.fg
            }

            HoverShared {
                id: chipArea
                anchors.fill: parent
                onClicked: { chips.value = chip.modelData[0]; chips.picked(chips.value) }
            }
        }
    }
}
