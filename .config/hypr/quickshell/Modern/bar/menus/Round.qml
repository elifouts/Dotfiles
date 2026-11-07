import QtQuick
import "../../../shared"
import "../../common"

Rectangle {
    id: rb
    property string glyph
    signal clicked()
    width: 26
    height: 26
    radius: Math.min(Theme.rounding, height / 2)
    color: Theme.alpha(Theme.fg, rbArea.containsMouse ? 0.14 : 0.07)
    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

    LabelShared {
        anchors.centerIn: parent
        text: rb.glyph
        font.pixelSize: 12
        color: rbArea.containsMouse ? Theme.bright : Theme.fg
    }

    HoverShared {
        id: rbArea
        anchors.fill: parent
        onClicked: rb.clicked()
    }
}
