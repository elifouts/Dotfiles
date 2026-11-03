-- reads the profile right out of Modern/, variant files beat base
local hypr = os.getenv("HOME") .. "/.config/hypr/"

-- old dotfiles from before state/ existed. can go once the laptop has pulled
local old = io.open(hypr .. ".active-profile")
if old then
    old:close()
    os.execute("mkdir -p '" .. hypr .. "state'")
    for from, to in pairs({ [".active-profile"] = "profile", [".active-bar"] = "bar", [".quickshell-bar"] = "bar-style",
        [".active-saved.json"] = "saved.json", [".color-theme"] = "color-theme", [".color-roles.json"] = "color-roles.json",
        [".color-roles-saved.json"] = "color-roles-saved.json", ["todos.json"] = "todos.json", ["settings.lua"] = "settings.lua" }) do
        os.rename(hypr .. from, hypr .. "state/" .. to)
    end
    for _, f in ipairs({ "startup.lua", "style.lua", "shortcuts.lua", "machine.lua" }) do os.remove(hypr .. f) end
    os.execute("find '" .. hypr .. "utilities' -maxdepth 1 -type l -delete")
end

local f = io.open(hypr .. "state/profile")
local profile = f and f:read("l") or "Modern/desktop"
if f then f:close() end
package.path = hypr .. profile .. "/?.lua;" .. hypr .. profile:match("[^/]+") .. "/base/?.lua;" .. hypr .. "state/?.lua;" .. package.path
require("hyprland")
