import QtQuick
import "../../shared"

MorphShared {
    id: p

    property var screen: null
    property bool jumps: false
    readonly property bool shown: active && !leaving
    readonly property bool hopping: hop.running
    property bool warm: false
    signal begin()
    signal moved()

    function show(scr) {
        scr = scr ?? HyprShared.focusedScreen()
        if (scr !== screen && (!active || jumps)) {
            reset()
            screen = scr
            moved()
            hop.restart()
            return
        }
        begin()
    }

    Component.onCompleted: if (!screen) screen = HyprShared.focusedScreen()
    onActiveChanged: {
        if (active) { warm = true; cool.stop() }
        else cool.restart()
    }
    Timer { id: hop; interval: 90; onTriggered: p.begin() }
    Timer { id: cool; interval: 120000; onTriggered: p.warm = false }
}
