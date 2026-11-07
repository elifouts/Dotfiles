.pragma library

var CURVE = [0.15, 0.85, 0.25, 1]

var PRESETS = {
    calm: { curve: [0.16, 1, 0.3, 1], speed: 0.6, window: "popin 90%", workspace: "slide" },
    balanced: { curve: [0.15, 0.85, 0.25, 1], speed: 1, window: "popin 90%", workspace: "slide" },
    snappy: { curve: [0.3, 1, 0.4, 1], speed: 1.7, window: "popin 60%", workspace: "slide" },
    bouncy: { curve: [0.34, 1.56, 0.64, 1], speed: 1, window: "popin 60%", workspace: "slidefade" }
}
var PRESET_OPTIONS = [
    { v: "theme", l: "Profile" }, { v: "calm", l: "Calm" }, { v: "balanced", l: "Balanced" },
    { v: "snappy", l: "Snappy" }, { v: "bouncy", l: "Bouncy" }, { v: "custom", l: "Custom" }
]
var WINDOWS = [{ v: "popin 90%", l: "Soft pop" }, { v: "popin 60%", l: "Deep pop" }, { v: "slide", l: "Slide" }, { v: "gnomed", l: "Gnome" }]
var WORKSPACES = [{ v: "slide", l: "Slide" }, { v: "slidevert", l: "Slide vertical" }, { v: "fade", l: "Fade" },
    { v: "slidefade", l: "Slide + fade" }, { v: "slidefadevert", l: "Slide + fade vertical" }]
var KEYS = ["config.animations.enabled", "utilities.animations", "animation.preset", "animation.curve", "animation.speed",
    "animation.window", "animation.workspace", "config.misc.animate_manual_resizes", "config.misc.animate_mouse_windowdragging"]

function pick(store, v, curve) {
    if (v === "theme") {
        store.setValues({ "animation.preset": "theme" })
        store.setMany({ "animation": null })
    } else if (v === "custom") {
        store.setMany({ "animation.preset": "custom", "animation.curve": curve })
    } else {
        var p = PRESETS[v]
        store.setMany({ "animation.preset": v, "animation.curve": p.curve, "animation.speed": p.speed,
            "animation.window": p.window, "animation.workspace": p.workspace })
    }
}
