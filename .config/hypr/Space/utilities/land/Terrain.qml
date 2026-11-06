import QtQuick
import "../common"

ShaderEffect {
    property int ws: 1
    property real screenX: 0
    property real pan: (ws - 1) * (Store.values["space.parallax"] ?? 1) + screenX / 2000 + drift
    property real zoom: 1
    property real lift: 0
    property real glow: 0
    property real drift: 0
    property real skyFade: 1
    property real wipe: 0
    property real rise: 0
    property real clear: 0
    property real orbit: 1
    property real endR: 0.09
    property vector4d sun: Qt.vector4d(-0.35, 0.6, 0.7, 0)
    property real kind: 0
    property vector4d moonEnd: Qt.vector4d(0, 0, 0, 0)
    property real seed: World.landSeed
    readonly property real aspect: width / Math.max(1, height)
    property bool asTheme: false
    property real hue: -1
    readonly property var pal: hue >= 0 ? World.palette(hue).colors : null
    property color bg: pal ? pal.color0 : Theme.bg
    property color accent: pal ? pal[asTheme ? "color" + Theme.slotOf("accent") : "color9"] : Theme.accent
    property color fg: pal ? (asTheme ? Theme.readable(pal.color7) : pal.color15) : Theme.fg
    property color tone: pal ? pal.color4 : Theme.c(4, "#24324f")
    property int fade: 0
    Behavior on bg { enabled: fade > 0; ColorAnimation { duration: fade; easing.type: Easing.InOutSine } }
    Behavior on accent { enabled: fade > 0; ColorAnimation { duration: fade; easing.type: Easing.InOutSine } }
    Behavior on fg { enabled: fade > 0; ColorAnimation { duration: fade; easing.type: Easing.InOutSine } }
    Behavior on tone { enabled: fade > 0; ColorAnimation { duration: fade; easing.type: Easing.InOutSine } }
    property color zenith: Theme.mix(bg, "#000000", 0.2)
    property color horizon: Theme.mix(accent, bg, 0.25)
    property color warm: Theme.mix(accent, "#ffd9b0", 0.6)
    property color far: Theme.mix(accent, bg, 0.55)
    property color near: Theme.mix(tone, "#0e1528", 0.88)
    property color moon: Theme.mix(fg, accent, 0.4)
    property color shade: Theme.mix(bg, "#000000", 0.5)
    property real moonless: 0
    fragmentShader: Qt.resolvedUrl("land.frag.qsb")
}
