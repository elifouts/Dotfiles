import QtQuick
import "../style/common"

Item {
    property bool on: false
    property real maxW: 440
    width: Math.min(maxW, parent.width)
    height: parent.height
    x: (parent.width - width) / 2
    opacity: on ? 1 : 0
    visible: opacity > 0
    transform: Translate { y: (1 - opacity) * 6 }
    Behavior on opacity { SettleShared { duration: Theme.move } }
}
