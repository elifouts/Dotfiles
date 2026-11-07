import QtQuick
import "../../common"

Column {
    id: sec
    property string title
    property int maxHeight: 240
    property string empty
    default property alias rows: list.data
    readonly property bool bare: sec.empty !== "" && list.implicitHeight < 4

    width: parent?.width ?? 280
    spacing: 4

    DecodeText { visible: sec.title !== ""; text: sec.title; height: 16 }
    Flickable {
        width: parent.width
        height: Math.min(sec.maxHeight, sec.bare ? Theme.menuRow : list.implicitHeight)
        contentHeight: list.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        clip: true
        Column { id: list; width: parent.width }
        DecodeText { x: 8; visible: sec.bare; text: sec.empty; height: Theme.menuRow }
    }
}
