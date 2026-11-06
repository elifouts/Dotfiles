.pragma library
.import "SchemaBase.js" as Base

var shown = Base.shown
var LAYOUT = {
    windows: [["Spacing", "Borders", "Opacity"], ["Tiling", "Border gradient"], ["Behavior"]],
    effects: [["Blur"], ["Shadow", "Glow", "Focus"]],
    animations: [["Motion", "Details"], ["Curve"]],
    input: [["Mouse", "Keyboard"], ["Cursor look", "Cursor behavior"], ["Touchpad", "Gestures"]],
    system: [["Display"], ["Behavior"]]
}
var PAGES = Object.keys(LAYOUT).map(function (id) {
    var p = Base.PAGES.find(function (x) { return x.id === id })
    return { id: id, columns: LAYOUT[id].map(function (col) {
        return col.map(function (label) { return p.sections.find(function (s) { return s.label === label }) })
    }) }
})

function keys() {
    return Base.keys().concat(["space.parallax", "space.clock24", "space.font"])
}
