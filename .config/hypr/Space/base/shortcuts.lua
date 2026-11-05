require("binds")
local mod = "SUPER"
local util = "~/.config/hypr/utilities/"
local space = function(name) return hl.dsp.exec_cmd(util .. "session/shells.sh space toggle " .. name) end

hl.bind(mod .. " + SUPER_L", space("launcher"), { release = true })
hl.bind(mod .. " + P", space("profiles"))
hl.bind(mod .. " + TAB", space("overview"))
hl.bind(mod .. " + L", hl.dsp.exec_cmd(util .. "session/lock.sh"))
hl.bind(mod .. " + M", hl.dsp.exit())
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd("~/.config/hypr/shared/media/spotify.sh toggle"))
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("ALT + TAB", space("scan"))
hl.bind("ALT + W", space("world"))
hl.bind("ALT + D", space("desk"))
hl.bind("ALT + S", space("settings"))
hl.bind("ALT + A", space("bar"))
