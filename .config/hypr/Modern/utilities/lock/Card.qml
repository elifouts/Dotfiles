import QtQuick
import "../common"

Rectangle {
    property real u: 1
    radius: Theme.rounding * u
    color: Lock.card
    border.width: 1
    border.color: Lock.edge
}
