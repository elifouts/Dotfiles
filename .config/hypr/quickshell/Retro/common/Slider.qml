import QtQuick

Item {
    id: sl
    property real value: 0
    property bool dimmed: false
    property bool scrollable: true
    property real step: 0.05
    property color fill: Theme.accent
    property color empty: Theme.low
    property int cells: Math.max(4, Math.floor(width / Math.max(1, cell.advanceWidth)))
    signal moved(real value)

    implicitHeight: 22
    TextMetrics { id: cell; font.family: Theme.font; font.pixelSize: Theme.size; text: "█" }
    readonly property int lit: Math.round(Math.max(0, Math.min(1, value)) * cells)

    Text {
        anchors.verticalCenter: parent.verticalCenter
        font.family: Theme.font
        font.pixelSize: Theme.size
        textFormat: Text.StyledText
        text: "<font color='" + (sl.dimmed ? Theme.dim : sl.fill) + "'>" + "█".repeat(sl.lit) + "</font>"
            + "<font color='" + sl.empty + "'>" + "░".repeat(sl.cells - sl.lit) + "</font>"
    }
    MouseArea {
        anchors.fill: parent
        function set(mx) { sl.moved(Math.max(0, Math.min(1, mx / width))) }
        onPressed: m => set(m.x)
        onPositionChanged: m => { if (pressed) set(m.x) }
        onWheel: w => w.accepted = sl.scrollable && (sl.moved(Math.max(0, Math.min(1, sl.value + (w.angleDelta.y > 0 ? sl.step : -sl.step)))), true)
    }
}
