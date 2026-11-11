.pragma library
.import "../../shared/SchemaShared.js" as Base

var shown = Base.shown
var LAYOUT = {
    windows: [["Spacing", "Borders", "Opacity"], ["Tiling", "Border gradient"], ["Behavior"]],
    effects: [["Blur"], ["Shadow", "Glow", "Focus"]],
    animations: [["Motion", "Details"], ["Curve"]],
    input: [["Mouse", "Keyboard"], ["Cursor look", "Cursor behavior"], ["Touchpad", "Gestures"]],
    system: [["Display", "Clock"], ["Behavior"]]
}

function s(k, label, min, max, step, dflt, unit) {
    return { type: "slider", key: "space.land." + k, id: k, label: label, min: min, max: max, step: step, dflt: dflt, unit: unit || "" }
}
function t(k, label, dflt) {
    return { type: "toggle", key: "space.land." + k, id: k, label: label, dflt: dflt }
}
var ATLAS_ON = { key: "space.land.atlas", eq: true }
var LAND = [
    [Base.section("Land", [
        s("relief", "Hills to mountains", 0, 1, 0.05, 0.4),
        s("height", "Height", 0.5, 1.6, 0.05, 1),
        s("snow", "Snow", 0, 1, 0.05, 0.5),
        s("haze", "Haze", 0, 1, 0.05, 0.5)
    ]), Base.section("Life", [
        s("flora", "Trees", 0, 2, 0.05, 1),
        s("treeSize", "Tree size", 0.5, 1.6, 0.05, 1),
        s("grass", "Grass", 0, 2, 0.05, 1.5),
        s("rocks", "Rocks", 0, 2, 0.05, 0.4),
        s("bases", "Bases", 0, 1, 0.05, 0.4)
    ])],
    [Base.section("Sky", [
        s("stars", "Stars", 0, 2, 0.05, 1),
        s("starSize", "Star size", 0.4, 2, 0.05, 1),
        s("galaxy", "Galaxy", 0, 1, 0.05, 0.25),
        s("galaxyTilt", "Galaxy angle", -90, 90, 5, 20, "°"),
        s("dusk", "Sunset", 0, 1, 0.05, 0.55),
        s("comets", "Shooting stars", 0, 6, 1, 1)
    ])],
    [Base.section("Moon", [
        t("atlas", "Atlas instead", false),
        s("atlasSize", "Atlas size", 0.5, 1.6, 0.05, 1),
        s("atlasGlow", "Core glow", 0, 1.5, 0.05, 0.8)
    ]), Base.section("Ships", [
        t("ship", "Landed ships", true),
        s("ships", "Landed", 0, 1, 0.05, 0.5),
        t("traffic", "Flying ships", true),
        s("fleet", "Flying", 0, 1, 0.05, 0.7)
    ]), Base.section("World", [
        s("variety", "Per world change", 0, 1, 0.05, 0.35),
        { type: "reland", label: "new land" },
        { type: "resetland", label: "reset" }
    ])]
]
LAND[2][0].controls[1].when = ATLAS_ON
LAND[2][0].controls[2].when = ATLAS_ON
var LAND_DEFS = LAND.reduce(function (a, col) { return a.concat.apply(a, col.map(function (x) { return x.controls })) }, []).filter(function (c) { return c.id })

var PAGES = [{ id: "land", columns: LAND }].concat(Object.keys(LAYOUT).map(function (id) {
    var p = Base.PAGES.find(function (x) { return x.id === id })
    return { id: id, columns: LAYOUT[id].map(function (col) {
        return col.map(function (label) { return p.sections.find(function (s) { return s.label === label }) })
    }) }
}))

function land(values, id) {
    var c = LAND_DEFS.find(function (x) { return x.id === id })
    var v = values["space.land." + id]
    return v === undefined || v === null ? c.dflt : v
}

function keys() {
    return Base.keys().concat(["space.parallax", "space.font"], LAND_DEFS.map(function (c) { return c.key }))
}
