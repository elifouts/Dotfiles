import QtQuick
import "../../shared"
import "../common"

Item {
    id: seg

    property var options: []
    property var current
    signal picked(var value)

    readonly property int index: {
        for (let i = 0; i < options.length; i++)
            if (options[i].v === current) return i
        return -1
    }
    readonly property real cell: options.length > 0 ? width / options.length : width

    implicitHeight: 30

    Rectangle {
        anchors.fill: parent
        radius: Theme.r(8)
        color: Theme.alpha(Theme.fg, 0.07)
    }

    Rectangle {
        visible: seg.index >= 0
        x: seg.index * seg.cell + 2
        y: 2
        width: seg.cell - 4
        height: parent.height - 4
        radius: Theme.r(6)
        color: Theme.soft(Theme.accent)
        Behavior on x { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutCubic } }
    }

    Repeater {
        model: seg.options

        Item {
            required property var modelData
            required property int index
            x: index * seg.cell
            width: seg.cell
            height: seg.height

            LabelShared {
                anchors.centerIn: parent
                width: parent.width - 8
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: modelData.l
                font.pixelSize: 12
                color: seg.index === index ? Theme.ink : area.containsMouse ? Theme.bright : Theme.fg
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }

            HoverShared {
                id: area
                anchors.fill: parent
                onClicked: seg.picked(modelData.v)
            }
        }
    }
}
