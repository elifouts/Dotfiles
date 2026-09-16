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
        gaps_in = 5,
        gaps_out = 5,
        border_size = 2,
        col = {
            active_border = colors.color11,
            inactive_border = colors.color8,
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 4,
        active_opacity = 0.94,
        inactive_opacity = 0.82,
        fullscreen_opacity = 1,
        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            ignore_opacity = true,
            xray = false,
            popups = true,
        },
        shadow = {
            enabled = true,
            range = 12,
            render_power = 3,
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
hl.curve("neon", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.curve("crt", { type = "bezier", points = { {0.5, 0}, {0.2, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "neon", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "crt", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "crt" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "neon", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "neon", style = "slidefadevert -35%" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "crt", style = "popin 70%" })

hl.layer_rule({ name = "quickshell-bar", match = { namespace = "quickshell" }, blur = true, ignore_alpha = 0.25 })
hl.layer_rule({ name = "quickshell-panels", match = { namespace = "quickshell-panel" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "selection-no-anim", match = { namespace = "selection" }, no_anim = true })
hl.layer_rule({ name = "quickshell-osd-blur", match = { namespace = "quickshell-osd" }, blur = true, ignore_alpha = 0.25 })