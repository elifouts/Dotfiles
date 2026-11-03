import QtQuick
import "../common"

// the land shader in theme colors, wallpaper and lock both use it
ShaderEffect {
    // which workspace and monitor, so the star map's takeoff view lines up with the real wallpaper
    property int ws: 1
    property real screenX: 0
    property real pan: (ws - 1) * (Store.values["space.parallax"] ?? 1) + screenX / 2000
    property real zoom: 1
    // 0 standing on the ground, 1 up in orbit looking back at the planet
    property real rise: 0
    // star map only: space goes see-through (clear), draw the planet here (orbit), and how small it ends (endR)
    property real clear: 0
    property real orbit: 1
    property real endR: 0.09
    // where the planet's light comes from, x right y up z toward you. the star map points it at the real star
    property vector4d sun: Qt.vector4d(-0.35, 0.6, 0.7, 0)
    // 1 draws a moon instead of a planet
    property real kind: 0
    // where the sky's moon ends up as you rise (x, y, radius, 1 behind / 2 in front), w 0 leaves it in the sky
    property vector4d moonEnd: Qt.vector4d(0, 0, 0, 0)
    // the world's terrain, a star map planet passes its own
    property real seed: World.landSeed
    readonly property real aspect: width / Math.max(1, height)
    // hue >= 0 draws that world's palette straight away, the star map lands before wal has caught up
    property real hue: -1
    readonly property var pal: hue >= 0 ? World.palette(hue).colors : null
    readonly property color bg: pal ? pal.color0 : Theme.bg
    readonly property color accent: pal ? pal.color9 : Theme.accent
    readonly property color fg: pal ? pal.color15 : Theme.fg
    readonly property color tone: pal ? pal.color4 : Theme.c(4, "#24324f")
    // the hills are the opposite hue, dark, like the navy against the pink
    property color zenith: Theme.mix(bg, "#000000", 0.2)
    property color horizon: Theme.mix(accent, bg, 0.25)
    property color warm: Theme.mix(accent, "#ffd9b0", 0.6)
    property color far: Theme.mix(accent, bg, 0.55)
    property color near: Theme.mix(tone, "#0e1528", 0.88)
    property color moon: Theme.mix(fg, accent, 0.4)
    property color shade: Theme.mix(bg, "#000000", 0.5)
    property real starClock: 0
    NumberAnimation on starClock {
        running: true
        from: 0
        to: 6.28318530718
        duration: 12000
        loops: Animation.Infinite
    }
    fragmentShader: Qt.resolvedUrl("land.frag.qsb")
}
