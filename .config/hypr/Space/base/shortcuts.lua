local mod = "SUPER"
local util = "~/.config/hypr/utilities/"
local space = function(name) return hl.dsp.exec_cmd(util .. "session/shells.sh space toggle " .. name) end
local function pop_out()
    local w = hl.get_active_window()
    if not w then return end
    local target = "address:" .. w.address
    if w.floating then
        hl.dispatch(hl.dsp.window.float({ action = "disable", window = target }))
        return
    end
    hl.dispatch(hl.dsp.window.float({ action = "enable", window = target }))
    local m = w.monitor
    if not m then return end
    local sw, sh = m.width / m.scale, m.height / m.scale
    if m.transform % 2 == 1 then sw, sh = sh, sw end
    local width, height
    if sw >= sh then
        width = sw * 0.6
        height = math.min(width * 10 / 16, sh * 0.7)
    else
        width = sw * 0.85
        height = math.min(width * 5 / 4, sh * 0.6)
    end
    hl.dispatch(hl.dsp.window.resize({ x = math.floor(width), y = math.floor(height), relative = false, window = target }))
    hl.dispatch(hl.dsp.window.center({ window = target }))
end

hl.bind(mod .. " + V", pop_out)
hl.bind(mod .. " + Q", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + B", hl.dsp.window.close())
hl.bind(mod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + M", hl.dsp.exit())
hl.bind(mod .. " + L", hl.dsp.exec_cmd(util .. "session/lock.sh"))
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
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd("pypr toggle term"))
hl.bind(mod .. " + G", hl.dsp.exec_cmd("pypr toggle music"))
hl.bind(mod .. " + T", hl.dsp.exec_cmd("pypr toggle taskbar"))
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("pypr toggle packages"))
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd("~/.config/hypr/shared/media/spotify.sh toggle"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("hyprshot -m region -o ~/Screenshots/"))
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m window -o ~/Screenshots/"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("hyprshot -m active -m output -o ~/Screenshots/"))
local osd = util .. "session/osd.sh "
for key, act in pairs({ XF86AudioMute = "vol-mute", XF86AudioMicMute = "mic-mute", Caps_Lock = "caps", ["CAPS + Caps_Lock"] = "caps",
    XF86AudioPlay = "play", XF86AudioNext = "next", XF86AudioPrev = "prev" }) do
    hl.bind(key, hl.dsp.exec_cmd(osd .. act), { locked = true })
end
for key, act in pairs({ XF86AudioRaiseVolume = "vol-up", XF86AudioLowerVolume = "vol-down",
    XF86MonBrightnessUp = "bright-up", XF86MonBrightnessDown = "bright-down" }) do
    hl.bind(key, hl.dsp.exec_cmd(osd .. act), { locked = true, repeating = true })
end

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
