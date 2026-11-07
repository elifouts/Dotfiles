import QtQuick
import "../../shared"

MouseArea {
    required property string key

    anchors.fill: parent
    acceptedButtons: Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: StoreShared.reset(key)
}
