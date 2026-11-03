hl.monitor({ output = "eDP-1", mode = "2560x1440@165", position = "0x0", scale = 1.6 })

return {
    -- defaults, settings panel can override
    defaults = {
        boot = { enabled = true, black_ms = 100 },
        cursor = { theme = "qogir-manjaro-dark", size = 16 },
    },
    sensitivity = .2,
}
