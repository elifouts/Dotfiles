local wal = require("wal")

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 8,
        border_size = 1,
        col = {
            active_border = wal.color(wal.accent),
            inactive_border = wal.color(wal.accent, "33"),
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 0,
        active_opacity = 1,
        inactive_opacity = 1,
        shadow = { enabled = false },
        glow = { enabled = false },
        blur = { enabled = false },
        dim_inactive = true,
        dim_strength = 0.12,
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    master = { new_status = "master" },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        focus_on_activate = true,
        background_color = wal.color(0),
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

hl.curve("snap", { type = "bezier", points = { { 0.1, 0.9 }, { 0.2, 1 } } })
hl.curve("step", { type = "bezier", points = { { 0.7, 0 }, { 0.3, 1 } } })
hl.animation({ leaf = "global", enabled = true, speed = 3, bezier = "snap" })
hl.animation({ leaf = "windows", enabled = true, speed = 2.2, bezier = "snap", style = "popin 96%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.4, bezier = "step", style = "popin 96%" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.6, bezier = "snap" })
hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "snap" })
hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "snap", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.4, bezier = "snap", style = "slidefade 8%" })
hl.window_rule({ name = "suppress-maximize-events", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
hl.window_rule({ name = "spotify-float", match = { class = "(?i)^spotify$" }, float = true })
for _, ns in ipairs({ "retro-bar", "retro-panel", "notification-popup", "osd", "welcome" }) do
    hl.layer_rule({ name = ns .. "-blur", match = { namespace = ns }, blur = true, ignore_alpha = 0.05, no_anim = true })
end
hl.layer_rule({ name = "widget-frames-blur", match = { namespace = "quickshell-widget-frames" }, blur = true, ignore_alpha = 0.01, no_anim = true })
hl.layer_rule({ name = "desk-frame-blur", match = { namespace = "^desk-.*-frame$" }, blur = true, ignore_alpha = 0.01, no_anim = true })
for _, ns in ipairs({ "retro-wall", "quickshell-widgets" }) do
    hl.layer_rule({ name = ns .. "-noanim", match = { namespace = ns }, no_anim = true })
end
