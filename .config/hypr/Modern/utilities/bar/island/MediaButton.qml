import QtQuick
import "../../common"

Text {
    id: b
    property bool ok: true
    property bool on: false
    signal pressed()
    anchors.verticalCenter: parent.verticalCenter
    font.family: Theme.sans
    font.pixelSize: 15
    color: !ok ? Theme.alpha(Theme.fg, 0.2) : on ? Theme.accent : bArea.containsMouse ? Theme.bright : Theme.fg
    Behavior on color { ColorAnimation { duration: Theme.fast } }
    Hover {
        id: bArea
        anchors.fill: parent
        anchors.margins: -8
        onClicked: if (b.ok) b.pressed()
    }
}
