import QtQuick
import "../../shared"

Rectangle {
    id: b

    property string label
    property bool primary: false
    property color tone: Theme.fg
    signal pressed()

    width: Math.max(64, caption.implicitWidth + 24)
    height: 32
    radius: Math.min(Theme.rounding, 10)
    color: primary ? Theme.soft(Theme.accent, area.containsMouse)
        : Theme.alpha(tone, area.containsMouse ? 0.12 : 0.055)
    scale: area.pressed ? 0.95 : 1
    Behavior on color { ColorAnimation { duration: Theme.fast } }
    Behavior on scale { NumberAnimation { duration: Theme.ms(120) } }

    LabelShared {
        id: caption
        anchors.centerIn: parent
        text: b.label
        font.pixelSize: 12
        color: b.primary ? Theme.ink : b.tone
    }

    HoverShared {
        id: area
        anchors.fill: parent
        onClicked: b.pressed()
    }
}
