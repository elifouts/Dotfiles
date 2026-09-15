-- Monitors, programs, autostart, and environment variables.

hl.monitor({ output = "eDP-1", mode = "2560x1440@165", position = "0x0", scale = 1.6 })

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

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("XCURSOR_SIZE", "12")

hl.device({ name = "epic-mouse-v1", sensitivity = 0 })