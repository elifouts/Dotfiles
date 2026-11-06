import QtQuick

Terrain {
    id: tw

    required property Terrain under
    property bool running: true

    layerMode: 2
    pan: under.pan
    zoom: under.zoom
    lift: under.lift
    glow: under.glow
    skyFade: under.skyFade
    seed: under.seed
    rise: under.rise
    moonless: under.moonless

    Timer {
        interval: 33
        repeat: true
        running: tw.running && tw.visible
        onTriggered: tw.starClock = (Date.now() % 12000) / 12000 * 6.28318530718
    }
}
