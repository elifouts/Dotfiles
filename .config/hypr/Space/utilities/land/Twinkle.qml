import QtQuick

// just the stars' twinkle, added on top of a still Terrain (layerMode 1 + layer.enabled) a gentle 30 times a second.
// a looping animation on the whole land shader repainted every pixel at the monitor's full refresh and kept the gpu at full clocks
Terrain {
    id: tw

    required property Terrain under
    property bool running: true

    layerMode: 2
    pan: under.pan
    zoom: under.zoom
    lift: under.lift
    glow: under.glow
    seed: under.seed
    rise: under.rise

    // the stars drift ~1% brightness a tick, smooth to the eye. the clock wraps every 12s like the old animation
    Timer {
        interval: 33
        repeat: true
        running: tw.running && tw.visible
        onTriggered: tw.starClock = (Date.now() % 12000) / 12000 * 6.28318530718
    }
}
