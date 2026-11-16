import QtQuick
import "../common"

Item {
    id: pill
    property bool framed: false
    property var scr: null
    default property alias content: inner.data
    width: inner.implicitWidth + 16
    height: Theme.bar

    Box { visible: pill.framed; anchors.fill: parent }
    Row { id: inner; x: 8; height: Theme.bar; spacing: 10 }
}
