local session = require("session")
local defaults = session.defaults
local boot = session.saved.boot or defaults.boot

hl.on("hyprland.start", function()
    if boot.enabled ~= false then
        hl.exec_cmd("BOOT_BLACK_MS=" .. (boot.black_ms or defaults.boot.black_ms) .. " qs -p ~/.config/hypr/quickshell/boot.qml --daemonize")
    end
end)

hl.device({ name = "epic-mouse-v1", sensitivity = 0 })
