import QtQuick
import "../../common"

Column {
    id: n
    property string glyph
    property string text
    property string action
    signal pressed()
    anchors.centerIn: parent
    spacing: 10

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        text: n.glyph
        font.pixelSize: 38
        color: Theme.alpha(Theme.fg, 0.35)
    }
    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        text: n.text
        font.pixelSize: 14
        color: Theme.dim
    }
    Button {
        anchors.horizontalCenter: parent.horizontalCenter
        primary: true
        label: n.action
        onPressed: n.pressed()
    }
}
