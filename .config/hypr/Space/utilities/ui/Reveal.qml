import QtQuick
import "../common"

Item {
    id: rv
    default property alias content: box.data
    property bool up: false
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
    function replay() { shut.stop(); t = 0; grow.restart() }
    Component.onCompleted: if (auto) open()

    NumberAnimation { id: grow; target: rv; property: "t"; to: 1; duration: Theme.open; easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: shut
        NumberAnimation { target: rv; property: "t"; to: 0; duration: Theme.quick; easing.type: Easing.InCubic }
        ScriptAction { script: rv.closed() }
    }
}
