import QtQuick
import "../common"

// the launcher's drop: clips the box and grows it out of an edge while it fades in. every box opens through this
Item {
    id: rv
    default property alias content: box.data
    // grow up out of the bottom edge instead of down out of the top
    property bool up: false
    // opens itself when it loads, set false to drive it yourself
    property bool auto: true
    property real t: 0
    signal closed()

    implicitWidth: box.childrenRect.width
    height: box.height * t
    clip: t < 1
    opacity: Math.min(1, t * 2)

    Item {
        id: box
        width: rv.width
        height: childrenRect.height
        y: rv.up ? 0 : rv.height - height
    }

    function open() { shut.stop(); grow.restart() }
    function close() { if (!shut.running) { grow.stop(); shut.start() } }
    // drops it open again, for a box whose contents just changed
    function replay() { shut.stop(); t = 0; grow.restart() }
    Component.onCompleted: if (auto) open()

    NumberAnimation { id: grow; target: rv; property: "t"; to: 1; duration: Theme.open; easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: shut
        NumberAnimation { target: rv; property: "t"; to: 0; duration: Theme.quick; easing.type: Easing.InCubic }
        ScriptAction { script: rv.closed() }
    }
}
