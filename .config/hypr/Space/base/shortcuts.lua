local mod = "SUPER"
local util = "~/.config/hypr/utilities/"
-- over ipc, GlobalShortcut crashed qs on exit and the damn thing kept respawning
local space = function(name) return hl.dsp.exec_cmd(util .. "shells.sh space toggle " .. name) end

hl.bind(mod .. " + Q", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + B", hl.dsp.window.close())
hl.bind(mod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + M", hl.dsp.exit())
hl.bind(mod .. " + L", hl.dsp.exec_cmd(util .. "lock.sh"))

-- tap super alone for the launcher
hl.bind(mod .. " + SUPER_L", space("launcher"), { release = true })
hl.bind(mod .. " + TAB", space("overview"))
hl.bind(mod .. " + P", space("profiles"))
hl.bind("ALT + TAB", space("scan"))
hl.bind("ALT + W", space("world"))
hl.bind("ALT + D", space("desk"))
hl.bind("ALT + S", space("settings"))
hl.bind("ALT + A", space("bar"))

for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mod .. " + " .. dir, hl.dsp.focus({ direction = dir }))
    hl.bind("ALT + " .. dir, hl.dsp.window.move({ direction = dir }))
end
for i = 1, 10 do
    hl.bind(mod .. " + " .. i % 10, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i % 10, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- pypr scratchpads, same as modern
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd("pypr toggle term"))
hl.bind(mod .. " + G", hl.dsp.exec_cmd("pypr toggle music"))
hl.bind(mod .. " + T", hl.dsp.exec_cmd("pypr toggle taskbar"))
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("pypr toggle packages"))
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd("~/.config/hypr/shared/media/spotify.sh toggle"))

hl.bind("CTRL + Print", hl.dsp.exec_cmd("hyprshot -m region -o ~/Screenshots/"))
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m window -o ~/Screenshots/"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("hyprshot -m active -m output -o ~/Screenshots/"))

-- same osd.sh as modern, the space shell draws it
local osd = util .. "osd.sh "
for key, act in pairs({ XF86AudioMute = "vol-mute", XF86AudioMicMute = "mic-mute", Caps_Lock = "caps", ["CAPS + Caps_Lock"] = "caps",
    XF86AudioPlay = "play", XF86AudioNext = "next", XF86AudioPrev = "prev" }) do
    hl.bind(key, hl.dsp.exec_cmd(osd .. act), { locked = true })
end
for key, act in pairs({ XF86AudioRaiseVolume = "vol-up", XF86AudioLowerVolume = "vol-down",
    XF86MonBrightnessUp = "bright-up", XF86MonBrightnessDown = "bright-down" }) do
    hl.bind(key, hl.dsp.exec_cmd(osd .. act), { locked = true, repeating = true })
end

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
