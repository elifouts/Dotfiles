import QtQuick
import "../style/common"

Text {
    visible: text !== ""
    x: 4
    width: parent.width - 8
    wrapMode: Text.Wrap
    font.family: Theme.sans
    font.pixelSize: 11
    color: Theme.warn
}
