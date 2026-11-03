local terminal = "kitty"
local fileManager = "thunar"
local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
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
hl.bind(mainMod .. " + V", pop_out)
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("~/.config/hypr/utilities/shells.sh launcher"), { release = true })
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("~/.config/hypr/utilities/shells.sh profiles"))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- Toggle split direction
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

local osd = "~/.config/hypr/utilities/osd.sh "
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(osd .. "vol-mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(osd .. "mic-mute"), { locked = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(osd .. "vol-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(osd .. "vol-down"), { locked = true, repeating = true })
-- caps lock counts as a modifier once it's on, so the plain bind alone never fires
hl.bind("Caps_Lock", hl.dsp.exec_cmd(osd .. "caps"), { locked = true })
hl.bind("CAPS + Caps_Lock", hl.dsp.exec_cmd(osd .. "caps"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(osd .. "bright-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(osd .. "bright-down"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(osd .. "play"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(osd .. "next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(osd .. "prev"), { locked = true })
hl.bind("ALT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind("ALT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind("ALT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind("ALT + down", hl.dsp.window.move({ direction = "down" }))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("hyprshot -m region -o ~/Screenshots/"))
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m window -o ~/Screenshots/"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("hyprshot -m active -m output -o ~/Screenshots/"))
hl.bind(mainMod .. " + l", hl.dsp.exec_cmd("~/.config/hypr/utilities/lock.sh"))
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("ALT + TAB", hl.dsp.exec_cmd("~/.config/hypr/utilities/shells.sh home"))
hl.bind("ALT + w", hl.dsp.exec_cmd("~/.config/hypr/utilities/shells.sh wallpaper"))
hl.bind("ALT + a", hl.dsp.exec_cmd("~/.config/hypr/utilities/bar.sh toggle"))
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("~/.config/hypr/utilities/shells.sh overview"))
hl.bind("ALT + S", hl.dsp.exec_cmd("~/.config/hypr/utilities/shells.sh settings"))
hl.bind("ALT + RETURN", hl.dsp.exec_cmd("~/.config/hypr/utilities/shells.sh music"))
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("pypr toggle packages"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("pypr toggle term"))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("pypr toggle music"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("pypr toggle taskbar"))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("~/.config/hypr/Modern/utilities/common/spotify.sh toggle"))

--local obs = hl.dsp.pass({ window = "class:com.obsproject.Studio" })
--hl.bind("CTRL + bracketleft", obs, { non_consuming = true })
--hl.bind("CTRL + bracketright", obs, { non_consuming = true })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
