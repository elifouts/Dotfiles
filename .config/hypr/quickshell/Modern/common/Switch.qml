import QtQuick
import "../../shared"

Rectangle {
    id: sw

    property bool checked: false
    property bool hot: area.containsMouse
    signal toggled()

    width: 38
    height: 22
    radius: Math.min(Theme.rounding, height / 2)
    color: checked ? Theme.soft(Theme.accent) : Theme.alpha(Theme.fg, hot ? 0.24 : 0.16)
    Behavior on color { ColorAnimation { duration: Theme.ms(240) } }

    readonly property real lead: Theme.ms(240)
    readonly property real trail: Theme.ms(360)
    property real l: checked ? width - 19 : 3
    property real r: checked ? width - 3 : 19
    Behavior on l { SettleShared { duration: sw.checked ? sw.trail : sw.lead } }
    Behavior on r { SettleShared { duration: sw.checked ? sw.lead : sw.trail } }

    Rectangle {
        y: 3
        x: sw.l
        width: sw.r - sw.l
        height: 16
        radius: Math.max(0, sw.radius - 3)
        color: sw.checked ? Theme.ink : Theme.fg
        Behavior on color { ColorAnimation { duration: sw.lead } }
    }

    HoverShared {
        id: area
        anchors.fill: parent
        onClicked: sw.toggled()
    }
}
