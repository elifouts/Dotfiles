require("binds")
local mod = "SUPER"
local util = "~/.config/hypr/utilities/"
local retro = function(name) return hl.dsp.exec_cmd(util .. "session/shells.sh retro toggle " .. name) end

hl.bind(mod .. " + SUPER_L", retro("launcher"), { release = true })
hl.bind(mod .. " + TAB", retro("overview"))
hl.bind(mod .. " + L", hl.dsp.exec_cmd(util .. "session/lock.sh"))
hl.bind(mod .. " + M", hl.dsp.exit())
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd("~/.config/hypr/quickshell/shared/spotify.sh toggle"))
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("ALT + TAB", retro("home"))
hl.bind("ALT + W", retro("wallpaper"))
hl.bind("ALT + D", retro("widgets"))
hl.bind("ALT + S", retro("settings"))
hl.bind("ALT + A", retro("bar"))
hl.bind("ALT + C", retro("crt"))
