import QtQuick
import "../style/common"

Tile {
    default property alias content: inner.data
    property alias spacing: inner.spacing
    width: parent ? parent.width : 0
    height: inner.implicitHeight + 20

    Column {
        id: inner
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 8
    }
}
