import QtQuick

// launcher, music and settings all did this on their own before
Morph {
    id: p

    property var screen: null
    // settings follows you to the other screen even while open
    property bool jumps: false
    readonly property bool shown: active && !leaving
    readonly property bool hopping: hop.running
    // i think this frees the textures once it's been closed a while, saves some memory
    property bool warm: false
    signal begin()
    signal moved()

    function show(scr) {
        scr = scr ?? Hypr.focusedScreen()
        if (scr !== screen && (!active || jumps)) {
            reset()
            screen = scr
            moved()
            hop.restart()
            return
        }
        begin()
    }

    Component.onCompleted: if (!screen) screen = Hypr.focusedScreen()
    onActiveChanged: {
        if (active) { warm = true; cool.stop() }
        else cool.restart()
    }
    Timer { id: hop; interval: 90; onTriggered: p.begin() }
    Timer { id: cool; interval: 120000; onTriggered: p.warm = false }
}
