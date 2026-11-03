.pragma library
.import "Motion.js" as Motion
// only the keys space's sheet touches
function keys() {
    return ["config.decoration.glow.enabled", "config.decoration.blur.enabled", "config.decoration.rounding",
        "config.general.gaps_in", "config.general.gaps_out", "config.general.border_size", "config.general.layout",
        "config.animations.enabled", "config.input.sensitivity", "config.input.touchpad.natural_scroll",
        "space.parallax", "space.clock24", "space.font"].concat(Motion.KEYS)
}
