local wal = require("wal")

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 12,
        border_size = 0,
        col = {
            active_border = wal.color(wal.accent, "cc"),
            inactive_border = wal.color(8, "44"),
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 3,
        rounding_power = 2,
        active_opacity = .8,
        inactive_opacity = .7,
        shadow = { enabled = false },
        glow = {
            enabled = true,
            range = 8,
            render_power = 3,
            color = wal.color(wal.accent, "40"),
            color_inactive = wal.color(wal.accent, "00"),
        },
        blur = {
            enabled = true,
            size = 4,
            passes = 2,
            vibrancy = 0.1696,
        },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    master = { new_status = "master" },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        focus_on_activate = true,
    },
    layers = { allow_new_top_layers_over_existing_fullscreen = true },
    render = { cm_auto_hdr = 0 },
    xwayland = { force_zero_scaling = true },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = require("machine").sensitivity,
        touchpad = { natural_scroll = true },
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("easy", { type = "spring", mass = 1, stiffness = 238.1191, damping = 24.21279333 })
hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, spring = "easy", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "easeOutQuint", style = "slide" })
hl.window_rule({ name = "suppress-maximize-events", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
hl.window_rule({ name = "spotify-float", match = { class = "(?i)^spotify$" }, float = true })
for _, ns in ipairs({ "space-bar", "space-launcher", "space-settings", "space-toast", "space-panel", "notification-popup", "welcome" }) do
    hl.layer_rule({ name = ns .. "-blur", match = { namespace = ns }, blur = true, ignore_alpha = 0.2, no_anim = true })
end
hl.layer_rule({ name = "osd-blur", match = { namespace = "osd" }, blur = true, ignore_alpha = 0.05, no_anim = true })
hl.layer_rule({ name = "space-home-blur", match = { namespace = "space-home" }, blur = true, ignore_alpha = 0, animation = "fade" })
for _, ns in ipairs({ "space-wall", "quickshell-widgets", "space-overview" }) do
    hl.layer_rule({ name = ns .. "-noanim", match = { namespace = ns }, no_anim = true })
end
