local defaults = require("machine").defaults
local saved = require("settings")
local cursor = saved.cursor or defaults.cursor
local util = "~/.config/hypr/utilities/"

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor " .. (cursor.theme or defaults.cursor.theme) .. " " .. (cursor.size or defaults.cursor.size))
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        .. "; systemctl --user reset-failed xdg-desktop-portal-hyprland xdg-desktop-portal"
        .. "; systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd(util .. "session/session.sh start")
    hl.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ 0")
    hl.exec_cmd("hypridle")
end)

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
local probe = io.popen([[sh -c 'for s in /sys/class/drm/card*-*/status; do grep -q "^connected" "$s" && readlink -f "${s%/*}/device/device/driver"; done' 2>/dev/null]])
local on_nvidia = probe and probe:read("*a"):find("nvidia") ~= nil
if probe then probe:close() end
if on_nvidia then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
end
hl.env("XCURSOR_THEME", cursor.theme or defaults.cursor.theme)
hl.env("XCURSOR_SIZE", tostring(cursor.size or defaults.cursor.size))

return { defaults = defaults, saved = saved }
