-- Colors, layout, decoration, animations, and layer rules.

local function load_wal_colors(path)
    local colors = {}
    local file = io.open(path, "r")
    if not file then return colors end
    for line in file:lines() do
        local idx, value = line:match("%$?color(%d+)%s*=%s*(%S+)")
        if idx then
            colors["color" .. idx] = value
        end
    end
    file:close()
    return colors
end

local colors = load_wal_colors(os.getenv("HOME") .. "/.cache/wal/colors-hyprland")

hl.config({
    general = {
        gaps_in = 2,
        gaps_out = 10,
        border_size = 0,
        col = {
            active_border = colors.color9,
            inactive_border = colors.color5,
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
            render_power = 5,
            color = "rgba(0,0,0,.5)",
        },
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
        sensitivity = .6,
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

hl.layer_rule({ name = "waybar-blur", match = { namespace = "waybar" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ name = "swaync-cc-blur", match = { namespace = "swaync-control-center" }, blur = true, ignore_alpha = .3 })
hl.layer_rule({ name = "swaync-notif-blur", match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = .3 })
hl.layer_rule({ name = "selection-no-anim", match = { namespace = "selection" }, no_anim = true })
hl.layer_rule({ name = "swayosd-blur", match = { namespace = "swayosd" }, blur = true, ignore_alpha = 0.5 })