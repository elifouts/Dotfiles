-- Monitors, programs, autostart, and environment variables.

hl.monitor({ output = "DP-4", mode = "1920x1080@74.97", position = "1480x64", scale = 1.00, transform = 1 })
hl.monitor({ output = "DP-5", mode = "1920x1080@239.96", position = "2560x480", scale = 1.00 })

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 12")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("quickshell --path ~/.config/hypr/utilities/quickshell/osd.qml --no-duplicate --daemonize")
    hl.exec_cmd("quickshell --path ~/.config/hypr/utilities/quickshell/bar.qml --no-duplicate --daemonize")
    hl.exec_cmd("pypr")
    hl.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ 0")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("quickshell --path ~/.config/hypr/utilities/quickshell/osd.qml --no-duplicate --daemonize")
end)

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("XCURSOR_SIZE", "12")

hl.device({ name = "epic-mouse-v1", sensitivity = 0 })