-- Converted from hyprland.conf -> hyprland.lua (Hyprland 0.55+ Lua config)
-- Reference: https://wiki.hypr.land/Configuring/Start/
-- hyprlock.conf / hypridle.conf are UNCHANGED — those tools still use hyprlang.

------------------
-- COLORS (pywal) --
------------------
-- ~/.cache/wal/colors-hyprland contains lines like: $color9 = 0xff484939
-- That's a hyprlang-style file, not valid Lua, so it can't be require()'d — parse it
-- directly at runtime instead. The 0xAARRGGBB values are already Hyprland's native
-- color format, so no reformatting is needed, just pass the string straight through.
local function load_wal_colors(path)
    local colors = {}
    local f = io.open(path, "r")
    if not f then return colors end
    for line in f:lines() do
        local idx, val = line:match("%$?color(%d+)%s*=%s*(%S+)")
        if idx then
            colors["color" .. idx] = val
        end
    end
    f:close()
    return colors
end

local colors = load_wal_colors(os.getenv("HOME") .. "/.cache/wal/colors-hyprland")

------------------
---- MONITORS ----
------------------
hl.monitor({ output = "eDP-1", mode = "2560x1440@165", position = "0x0", scale = 1.6 })

---------------------
---- MY PROGRAMS ----
---------------------
local terminal = "kitty"
local fileManager = "thunar"
local menu = "wofi -n"

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor qogir-manjaro-dark 16")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("swayosd-server -s ~/.config/swayosd/style.css")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("pypr")
    hl.exec_cmd("swaync-client -df")
    hl.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ 0")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("sleep .5 && swww restore")
    hl.exec_cmd("awww-daemon")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("XCURSOR_SIZE", "12")

-- NOTE: your old file had a bare top-level `cursor = Bibata-Modern-Ice` line. That is not
-- a documented hyprlang/lua option — cursor theme is set via `hyprctl setcursor` above
-- (already present in your autostart). It was likely a no-op, so it's dropped here.
-- Confirm at wiki.hypr.land if you believe it did something.

-----------------------
---- LOOK AND FEEL ----
-----------------------
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
        sensitivity = .2,
        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.device({ name = "epic-mouse-v1", sensitivity = 0 })

-------------------
---- ANIMATIONS ----
-------------------
hl.config({ animations = { enabled = true } })

hl.curve("fluid", { type = "bezier", points = { {0.15, 0.85}, {0.25, 1} } })
hl.curve("snappy", { type = "bezier", points = { {0.3, 1}, {0.4, 1} } })

hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "fluid", style = "popin 5%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "snappy" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "snappy" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.7, bezier = "snappy", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "fluid", style = "slidefadevert -35%" })
hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "snappy", style = "popin 70%" })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
-- togglesplit (J) was already commented out in your original file
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen()) -- VERIFY: no bare-call example in official docs; confirm args at wiki.hypr.land/Configuring/Basics/Dispatchers/

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume +15"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume -15"))
-- For you Riley
hl.bind("Caps_Lock", hl.dsp.exec_cmd("sleep 0.1 && swayosd-client --caps-lock"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness +10"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness -10"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("swayosd-client --playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("swayosd-client --playerctl previous"))

-- VERIFY: keyboard-driven movewindow (swap window in a direction) isn't shown in the
-- official example file — only mouse-drag window.move is. This follows the same
-- {direction=...} shape hl.dsp.focus uses; confirm before relying on it.
hl.bind("ALT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind("ALT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind("ALT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind("ALT + down", hl.dsp.window.move({ direction = "down" }))

hl.bind("CTRL + Print", hl.dsp.exec_cmd("hyprshot -m region -o ~/Screenshots/"))
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m window -o ~/Screenshots/"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("hyprshot -m active -m output -o ~/Screenshots/"))
hl.bind(mainMod .. " + l", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("ALT + TAB", hl.dsp.exec_cmd("wlogout -b 2"))
hl.bind("ALT + w", hl.dsp.exec_cmd("~/.config/hypr/wallpaper.sh"))
hl.bind("ALT + a", hl.dsp.exec_cmd("~/.config/waybar/scripts/refresh.sh"))
hl.bind("ALT + B", hl.dsp.exec_cmd("~/.config/waybar/scripts/select.sh"))
hl.bind("ALT + r", hl.dsp.exec_cmd("~/.config/swaync/refresh.sh"))
hl.bind(mainMod .. " + M", hl.dsp.exit()) -- VERIFY: official example wraps this with a hyprshutdown check; consider adopting that pattern
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("pypr toggle term"))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("pypr toggle music"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("pypr toggle taskbar"))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("pypr toggle spotify"))
-- CTRL+ESCAPE -> gksu was left commented out in your original file too

--------------------------------
---- LAYER RULES ----
--------------------------------
-- VERIFY: field names below (blur / ignore_alpha / no_anim) are inferred from the legacy
-- hyprlang keywords, not confirmed against a lua-specific layer-rule example. Check
-- wiki.hypr.land/Configuring/Basics/Layer-Rules/ before relying on exact spelling.
hl.layer_rule({ name = "waybar-blur", match = { namespace = "waybar" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ name = "swaync-cc-blur", match = { namespace = "swaync-control-center" }, blur = true, ignore_alpha = .3 })
hl.layer_rule({ name = "swaync-notif-blur", match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = .3 })
hl.layer_rule({ name = "selection-no-anim", match = { namespace = "selection" }, no_anim = true })
hl.layer_rule({ name = "swayosd-blur", match = { namespace = "swayosd" }, blur = true, ignore_alpha = 0.5 })
