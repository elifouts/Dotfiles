import QtQuick
import "../../shared"

Rectangle {
    id: b
    property string label
    property bool primary: false
    property color tone: Theme.fg
    signal pressed()

    width: caption.implicitWidth + 20
    height: 22
    color: area.containsMouse || b.primary ? Theme.accent : "transparent"
    border.width: 1
    border.color: Theme.accent

    Type { id: caption; anchors.centerIn: parent; text: b.label; color: area.containsMouse || b.primary ? Theme.bg : b.tone }
    HoverShared { id: area; anchors.fill: parent; onClicked: b.pressed() }
}
