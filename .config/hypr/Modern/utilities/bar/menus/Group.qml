import QtQuick
import Quickshell.Widgets
import "../../common"

Column {
    id: sec

    property string title: ""
    property int maxHeight: 240
    property string empty: ""
    default property alias rows: list.data

    width: parent ? parent.width : 0
    spacing: 6

    Label {
        x: 4
        visible: sec.title !== ""
        text: sec.title.toUpperCase()
        font.pixelSize: 10
        font.letterSpacing: 1.6
        color: Theme.dim
    }

    // rows go edge to edge and get clipped to the corners so a highlight isn't a box in a box
    ClippingRectangle {
        width: parent.width
        height: Math.min(sec.maxHeight, Math.max(sec.empty !== "" && list.implicitHeight < 4 ? 40 : 0, list.implicitHeight))
        radius: Math.min(Theme.rounding, 12)
        color: Theme.alpha(Theme.fg, 0.055)

        Flickable {
            anchors.fill: parent
            contentHeight: list.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            Column {
                id: list
                width: parent.width
            }
        }

        Label {
            anchors.centerIn: parent
            visible: sec.empty !== "" && list.implicitHeight < 4
            text: sec.empty
            font.pixelSize: 12
            color: Theme.dim
        }
    }
}
