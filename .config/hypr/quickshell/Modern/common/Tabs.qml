import QtQuick
import "../../shared"

Item {
    id: tabs

    property var model: []
    property int index: 0
    signal picked(int i)

    height: 34
    readonly property real gap: 6
    readonly property real cell: (width - gap * (model.length - 1)) / model.length

    Rectangle {
        width: tabs.cell
        height: parent.height
        radius: Theme.r(9)
        x: tabs.index * (tabs.cell + tabs.gap)
        color: Theme.soft(Theme.accent)
        Behavior on x { NumberAnimation { duration: Theme.ms(340); easing.type: Easing.OutCubic } }
    }

    Repeater {
        model: tabs.model

        Item {
            id: tab
            required property var modelData
            required property int index
            readonly property bool on: tabs.index === index
            x: index * (tabs.cell + tabs.gap)
            width: tabs.cell
            height: tabs.height

            Rectangle {
                anchors.fill: parent
                radius: Theme.r(9)
                color: Theme.alpha(Theme.fg, tab.on ? 0 : (tabArea.containsMouse ? 0.12 : 0.05))
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }

            LabelShared {
                anchors.centerIn: parent
                text: tab.modelData.icon
                font.pixelSize: 15
                scale: tab.on ? 1.12 : 1
                color: tab.on ? Theme.ink : tabArea.containsMouse ? Theme.bright : Theme.fg
                Behavior on scale { NumberAnimation { duration: Theme.ms(260); easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }

            HoverShared {
                id: tabArea
                anchors.fill: parent
                onClicked: tabs.picked(tab.index)
            }
        }
    }
}
