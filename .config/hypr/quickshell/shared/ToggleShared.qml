import QtQuick
import "../style/common"

Item {
    id: tg
    property string label
    property bool checked: false
    signal toggled()
    width: parent ? parent.width : 0
    height: 26

    Say {
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        text: tg.label
        font.pixelSize: 12
        color: Theme.fg
    }
    Switch {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: tg.checked
        onToggled: { tg.checked = !tg.checked; tg.toggled() }
    }
}
