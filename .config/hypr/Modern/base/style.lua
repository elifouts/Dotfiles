local wal = require("wal")

hl.config({
    general = {
        gaps_in = 2,
        gaps_out = 10,
        border_size = 0,
        col = {
            active_border = wal.color(wal.accent),
            inactive_border = wal.color(5),
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        active_opacity = 0.78,
        inactive_opacity = 0.7,
        fullscreen_opacity = 1,
        blur = {
            enabled = true,
            size = 3,
            passes = 5,
            ignore_opacity = true,
            xray = false,
            popups = true,
        },
        shadow = {
            enabled = true,
            range = 15,
            render_power = 4,
            color = "rgba(0,0,0,.5)",
        },
    },
    render = {
        cm_auto_hdr = 0,
    },
    xwayland = {
        force_zero_scaling = true,
    },
    dwindle = {
        preserve_split = true,
    },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = true,
        focus_on_activate = true,
    },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        focus_on_close = 1,
        sensitivity = require("machine").sensitivity,
        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.config({ animations = { enabled = true } })
hl.curve("fluid", { type = "bezier", points = { {0.15, 0.85}, {0.25, 1} } })
hl.curve("snappy", { type = "bezier", points = { {0.3, 1}, {0.4, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "fluid", style = "popin 5%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "snappy" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "snappy" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.7, bezier = "snappy", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "fluid", style = "slidefadevert -35%" })
hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "snappy", style = "popin 70%" })
hl.window_rule({ match = { class = "(?i)^spotify$" }, float = true })
hl.layer_rule({ name = "waybar-blur", match = { namespace = "waybar" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ name = "quickshell-bar-blur", match = { namespace = "quickshell-bar" }, blur = true, ignore_alpha = 0.3, no_anim = true })
hl.layer_rule({ name = "quickshell-overview-noanim", match = { namespace = "quickshell-overview" }, no_anim = true })
hl.layer_rule({ name = "notification-popup-blur", match = { namespace = "notification-popup" }, blur = true, ignore_alpha = 0.5, no_anim = true })
hl.layer_rule({ name = "quickshell-widgets-noanim", match = { namespace = "quickshell-widgets" }, no_anim = true })
hl.layer_rule({ name = "selection-no-anim", match = { namespace = "selection" }, no_anim = true })
hl.layer_rule({ name = "osd-blur", match = { namespace = "osd" }, blur = true, ignore_alpha = 0.05, no_anim = true })
hl.layer_rule({ name = "launcher-blur", match = { namespace = "launcher" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ name = "wallpaper-picker-noanim", match = { namespace = "wallpaper-picker" }, no_anim = true })
hl.layer_rule({ name = "lock-handoff-fade", match = { namespace = "lock-handoff" }, animation = "fade" })
hl.layer_rule({ name = "wallpaper-picker-preview-noanim", match = { namespace = "wallpaper-picker-preview" }, no_anim = true })
hl.layer_rule({ name = "settings-panel-blur", match = { namespace = "settings-panel" }, blur = true, ignore_alpha = 0.05, no_anim = true })
hl.layer_rule({ name = "app-drawer-blur", match = { namespace = "app-drawer" }, blur = true, ignore_alpha = 0.05, no_anim = true })
hl.layer_rule({ name = "music-player-blur", match = { namespace = "music-player" }, blur = true, ignore_alpha = 0.05, no_anim = true })
hl.layer_rule({ name = "welcome-blur", match = { namespace = "welcome"}, blur = true, ignore_alpha = 0.05, no_anim = true})
hl.layer_rule({ name = "profile-switcher-blur", match = { namespace = "profile-switcher"}, blur = true, ignore_alpha = 0.05, no_anim = true})
hl.layer_rule({ name = "boot-sequence-blur", match = { namespace = "boot-sequence" }, blur = true, ignore_alpha = 0.15, no_anim = true })
