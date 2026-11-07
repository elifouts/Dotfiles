import QtQuick
import Quickshell.Widgets
import "../../../shared"
import "../../common"

Item {
    id: h
    property string title
    property string note
    property string icon
    default property alias trailing: tail.data
    width: parent ? parent.width : 0
    height: 26

    IconImage {
        id: appIcon
        anchors.verticalCenter: parent.verticalCenter
        visible: h.icon !== ""
        implicitSize: 18
        source: h.icon
    }
    LabelShared {
        anchors.left: appIcon.visible ? appIcon.right : parent.left
        anchors.leftMargin: appIcon.visible ? 10 : 0
        anchors.right: noteText.left
        anchors.verticalCenter: parent.verticalCenter
        text: h.title
        elide: Text.ElideRight
        font.pixelSize: 16
        color: Theme.bright
    }
    LabelShared {
        id: noteText
        anchors.right: tail.left
        anchors.rightMargin: tail.width > 0 ? 10 : 0
        anchors.verticalCenter: parent.verticalCenter
        text: h.note
        font.pixelSize: 10
        color: Theme.dim
    }
    Row {
        id: tail
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
    }
}
