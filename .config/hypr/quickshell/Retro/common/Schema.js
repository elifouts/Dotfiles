.pragma library
.import "../../shared/SchemaShared.js" as Base

var shown = Base.shown
var opt = Base.opt
var LAYOUT = {
    windows: [["Spacing", "Borders", "Opacity"], ["Tiling", "Behavior"]],
    effects: [["Blur", "Shadow"], ["Glow", "Focus"]],
    animations: [["Motion", "Details"], ["Curve"]],
    input: [["Mouse", "Keyboard", "Touchpad"], ["Cursor look", "Cursor behavior", "Gestures"]],
    system: [["Display", "Clock"], ["Behavior"]]
}

function crt(k, label, min, max, step, dflt) { return Base.slider("crt." + k, label, min, max, step, "", { dflt: dflt }) }
function wall(k, label, min, max, step, dflt) { return Base.slider("filter." + k, label, min, max, step, "", { dflt: dflt }) }

var SCREEN = [
    [Base.section("Tube", [
        Base.toggle("crt.on", "Screen filter", { dflt: true }),
        crt("mono", "Phosphor tint", 0, 1, 0.05, 0.85),
        crt("glow", "Glow", 0, 1.5, 0.05, 0.5),
        crt("lines", "Scanlines", 0, 0.9, 0.05, 0.35)
    ]), Base.section("Glass", [
        crt("vignette", "Vignette", 0, 1, 0.05, 0.5),
        crt("corners", "Round corners", 0, 1, 0.05, 0.5),
        crt("bend", "Curve", 0, 1, 0.05, 0),
        crt("grain", "Grain", 0, 1, 0.05, 0.4)
    ])],
    [Base.section("Wallpaper", [
        Base.toggle("filter.on", "Wallpaper", { dflt: true }),
        Base.choice("filter.tone", "Color", [opt("lines", "Lines", { dflt: true }), opt("tube", "Tube"), opt("palette", "Palette"), opt("source", "Source")]),
        Base.choice("filter.dither", "Dither", [opt("bayer", "Bayer", { dflt: true }), opt("fine", "Fine"), opt("halftone", "Halftone"), opt("diffuse", "Diffuse"), opt("none", "None")]),
        wall("pixel", "Pixel size", 1, 6, 1, 2),
        wall("levels", "Levels", 2, 12, 1, 6),
        wall("contrast", "Contrast", 0, 1, 0.05, 0.5),
        wall("bright", "Brightness", 0.1, 1, 0.05, 0.4)
    ])]
]

var PRESETS = [
    { l: "Terminal", v: { "crt.mono": 0.85, "crt.glow": 0.5, "crt.lines": 0.35, "crt.vignette": 0.5, "crt.corners": 0.5, "crt.bend": 0, "crt.grain": 0.4 } },
    { l: "Clean", v: { "crt.mono": 0.35, "crt.glow": 0.2, "crt.lines": 0.12, "crt.vignette": 0.2, "crt.corners": 0.2, "crt.bend": 0, "crt.grain": 0.1 } },
    { l: "Worn", v: { "crt.mono": 1, "crt.glow": 1, "crt.lines": 0.6, "crt.vignette": 0.9, "crt.corners": 1, "crt.bend": 0.3, "crt.grain": 0.9 } },
    { l: "Arcade", v: { "crt.mono": 0, "crt.glow": 0.8, "crt.lines": 0.5, "crt.vignette": 0.6, "crt.corners": 0.7, "crt.bend": 0.2, "crt.grain": 0.3 } }
]

var DEFS = SCREEN.reduce(function (a, col) { return a.concat.apply(a, col.map(function (x) { return x.controls })) }, [])

var PAGES = [{ id: "screen", columns: SCREEN }].concat(Object.keys(LAYOUT).map(function (id) {
    var p = Base.PAGES.find(function (x) { return x.id === id })
    return { id: id, columns: LAYOUT[id].map(function (col) {
        return col.map(function (label) { return p.sections.find(function (s) { return s.label === label }) }).filter(function (s) { return !!s })
    }) }
}))

function keys() {
    return Base.keys().concat(["retro.font", "retro.size"], DEFS.map(function (c) { return c.key }))
}
