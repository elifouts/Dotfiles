import QtQuick
import "../../shared"

Item {
    id: sl

    property real value: 0
    property real from: 0
    property real to: 1
    property bool dimmed: false
    property bool scrollable: true
    property real step: (to - from) / 20
    readonly property bool hot: area.containsMouse || area.pressed
    signal moved(real value)

    implicitHeight: 20

    readonly property real frac: Math.max(0, Math.min(1, (value - from) / (to - from)))

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: sl.hot ? 6 : 4
        radius: height / 2
        color: Theme.alpha(Theme.fg, 0.16)
        Behavior on height { NumberAnimation { duration: Theme.fast } }

        Rectangle {
            width: Math.max(parent.height, parent.width * sl.frac)
            height: parent.height
            radius: parent.radius
            color: sl.dimmed ? Theme.alpha(Theme.fg, 0.4) : Theme.accent
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
    }

    Rectangle {
        x: Math.max(0, Math.min(sl.width - width, sl.width * sl.frac - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: 12
        height: 12
        radius: 6
        color: Theme.bright
        scale: sl.hot ? 1 : 0
        Behavior on scale { SettleShared { duration: Theme.ms(140) } }
    }

    HoverShared {
        id: area
        anchors.fill: parent
        anchors.topMargin: -8
        anchors.bottomMargin: -8
        function set(x) { sl.moved(sl.from + Math.max(0, Math.min(1, x / sl.width)) * (sl.to - sl.from)) }
        onPressed: m => set(m.x)
        onPositionChanged: m => { if (pressed) set(m.x) }
        onWheel: w => {
            if (!sl.scrollable) { w.accepted = false; return }
            sl.moved(Math.max(sl.from, Math.min(sl.to, sl.value + (w.angleDelta.y > 0 ? 1 : -1) * sl.step)))
        }
    }
}
