import QtQuick
import "../../shared"
import "../common"
import "../common/Schema.js" as Schema

ShaderEffect {
    property int ws: 1
    property real screenX: 0
    property real pan: (ws - 1) * (StoreShared.values["space.parallax"] ?? 1) + screenX / 2000 + drift
    property real zoom: 1
    property real lift: 0
    property real glow: 0
    property real drift: 0
    property real skyFade: 1
    property real wipe: 0
    property real beneath: -1
    property vector4d view: Qt.vector4d(0, 0, 0, 0)
    property vector4d viewSize: Qt.vector4d(0, 0, 0, 0)
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
    readonly property var lv: StoreShared.values
    property real relief: Schema.land(lv, "relief")
    property real landH: Schema.land(lv, "height")
    property real bases: Schema.land(lv, "bases")
    property real treeSize: Schema.land(lv, "treeSize")
    property real atlasSize: Schema.land(lv, "atlasSize")
    property real snow: Schema.land(lv, "snow")
    property real fleet: Schema.land(lv, "fleet")
    property real flora: Schema.land(lv, "flora")
    property real grassy: Schema.land(lv, "grass")
    property real rocks: Schema.land(lv, "rocks")
    property real haze: Schema.land(lv, "haze")
    property real variety: Schema.land(lv, "variety")
    property real starAmt: Schema.land(lv, "stars")
    property real starSize: Schema.land(lv, "starSize")
    property real galaxy: Schema.land(lv, "galaxy")
    property real galaxyTilt: Schema.land(lv, "galaxyTilt") * Math.PI / 180
    property real dusk: Schema.land(lv, "dusk")
    property real atlasGlow: Schema.land(lv, "atlasGlow")
    property real ships: Schema.land(lv, "ships")
    property bool atlasOk: true
    property real atlas: atlasOk && Schema.land(lv, "atlas") ? 1 : 0
    property real ship: Schema.land(lv, "ship") ? 1 : 0
    property real traffic: Schema.land(lv, "traffic") ? 1 : 0
    property real comet: Schema.land(lv, "comets")
    Behavior on atlas { NumberAnimation { duration: Theme.ms(700); easing.type: Easing.InOutSine } }
    Behavior on ship { NumberAnimation { duration: Theme.ms(400); easing.type: Easing.InOutSine } }
    Behavior on traffic { NumberAnimation { duration: Theme.ms(400); easing.type: Easing.InOutSine } }
    Behavior on comet { NumberAnimation { duration: Theme.ms(400); easing.type: Easing.InOutSine } }
    fragmentShader: Qt.resolvedUrl("terrain.frag.qsb")
}
