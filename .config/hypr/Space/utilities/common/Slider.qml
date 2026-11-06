import QtQuick

Item {
    id: sl
    property real value: 0
    property bool dimmed: false
    property bool scrollable: true
    property real step: 0.05
    property int cells: 24
    signal moved(real value)

    implicitHeight: 22

    Repeater {
        model: sl.cells
        Rectangle {
            required property int index
            x: index * sl.width / sl.cells
            width: sl.width / sl.cells - 2
            height: 6
            anchors.verticalCenter: parent.verticalCenter
            color: index < Math.round(sl.value * sl.cells) && !sl.dimmed ? Theme.accent : Theme.faint
        }
    }
    MouseArea {
        anchors.fill: parent
        function set(mx) { sl.moved(Math.max(0, Math.min(1, mx / width))) }
        onPressed: m => set(m.x)
        onPositionChanged: m => { if (pressed) set(m.x) }
        onWheel: w => w.accepted = sl.scrollable && (sl.moved(Math.max(0, Math.min(1, sl.value + (w.angleDelta.y > 0 ? sl.step : -sl.step)))), true)
    }
}
