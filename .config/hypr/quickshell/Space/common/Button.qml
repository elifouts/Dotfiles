import QtQuick
import "../../shared"

Rectangle {
    id: b

    property string label
    property bool primary: false
    property color tone: Theme.fg
    signal pressed()

    width: caption.implicitWidth + 18
    height: 24
    color: Theme.alpha(Theme.accent, area.containsMouse ? 0.18 : primary ? 0.12 : 0.04)
    border.width: 1
    border.color: Theme.alpha(Theme.accent, primary ? 0.7 : 0.25)

    DecodeText { id: caption; anchors.centerIn: parent; text: b.label; color: b.primary ? Theme.accent : b.tone }
    HoverShared { id: area; anchors.fill: parent; onClicked: b.pressed() }
}
