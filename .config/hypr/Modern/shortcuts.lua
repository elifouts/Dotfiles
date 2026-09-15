-- Keyboard, mouse, and gesture shortcuts.

local terminal = "kitty"
local fileManager = "thunar"
local menu = "wofi -n"
local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

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
hl.bind("Caps_Lock", hl.dsp.exec_cmd("sleep 0.1 && swayosd-client --caps-lock"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness +10"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness -10"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("swayosd-client --playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("swayosd-client --playerctl previous"))

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
hl.bind("ALT + H", hl.dsp.exec_cmd("~/.config/hypr/select.sh"))
hl.bind("ALT + r", hl.dsp.exec_cmd("~/.config/swaync/refresh.sh"))
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("pypr toggle term"))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("pypr toggle music"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("pypr toggle taskbar"))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("pypr toggle spotify"))

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })