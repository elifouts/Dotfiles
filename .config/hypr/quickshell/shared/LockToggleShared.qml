import QtQuick
import "../style/common"

Item {
    id: row

    property string label
    property bool checked
    property real u: 1
    signal toggled()

    width: parent ? parent.width : 240
    height: 34 * u

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2 * row.u
        radius: LockShared.corner(height, row.u)
        color: Theme.alpha(Theme.fg, area.containsMouse ? 0.06 : 0)
        Behavior on color { ColorAnimation { duration: Theme.ms(140) } }
    }

    LabelShared {
        anchors.left: parent.left
        anchors.leftMargin: 8 * row.u
        anchors.verticalCenter: parent.verticalCenter
        text: row.label
        font.pixelSize: 13 * row.u
        color: row.checked ? LockShared.ink : Theme.alpha(LockShared.ink, 0.7)
        Behavior on color { ColorAnimation { duration: Theme.ms(180) } }
    }

    Switch {
        anchors.right: parent.right
        anchors.rightMargin: 8 * row.u
        anchors.verticalCenter: parent.verticalCenter
        scale: row.u
        transformOrigin: Item.Right
        checked: row.checked
        hot: area.containsMouse
    }

    HoverShared {
        id: area
        anchors.fill: parent
        onClicked: row.toggled()
    }
}
