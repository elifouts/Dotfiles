local PRESET = "apple_extreme"
local PRESET_VALUES = {
    inherits = "glass",

    noise_strength = 0.27,
    blur_iterations = 2,
    blur_strength = 2.3,
    glass_opacity = 1.0,

    refraction_strength = 5.0,
    refraction_flow = 0.03,
    refraction_spread = 0.12,
    lens_distortion = 6.4,
    chromatic_aberration = 0.5,

    edge_thickness = 0.045,
    edge_thickness_px = 33.0,
    edge_height = 0.0,
    bevel_strength = 0,
    bevel_size = 6.0,
    bevel_color = 0xffffff00,
    bevel_tint = 0.0,
    bevel_angle = 315.0,
    bevel_shadow = 0.0,

    fresnel_strength = 0.0,
    fresnel_tint = 0.0,
    fresnel_color = 0xffffff00,
    fresnel_reflection = 0.0,
    specular_strength = 0.0,
    specular_angle = 0.0,

    tint_color = 0x50423933,

    self_sample = 0.0,
    xray = 0,
    focus_light = 0.0,
    focus_light_color = 0xffffff00,
    frost = 0.0,
    frost_blur = 10.0,

    brightness = 1.27,
    contrast = 1.32,
    saturation = 0.4,

    dark = {
        vibrancy = 1.59,
        vibrancy_darkness = 0.0,
        adaptive_dim = 0.21,
        adaptive_boost = 0.0,
    },
    light = {
        vibrancy = 1.59,
        vibrancy_darkness = 0.0,
        adaptive_dim = 0.21,
        adaptive_boost = 0.0,
    },
}

if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.config({
        enabled = false,
        manage_window_blur = true,
        skip_opaque_windows = true,
        blur_fold = true,
        default_theme = "light",
        default_preset = PRESET,

        blur_strength = 2.0,
        blur_iterations = 2,
        noise_strength = 0.1,
        refraction_strength = 0.6,
        refraction_flow = 0.0,
        refraction_spread = 1.0,
        chromatic_aberration = 0.5,
        fresnel_strength = 0.6,
        fresnel_tint = 0.0,
        fresnel_color = 0xffffff00,
        fresnel_reflection = 0.0,
        specular_strength = 0.8,
        specular_angle = 0.0,
        bevel_strength = 0.0,
        bevel_size = 6.0,
        bevel_color = 0xffffff00,
        bevel_tint = 0.0,
        bevel_angle = 315.0,
        bevel_shadow = 0.0,
        glass_opacity = 1.0,
        edge_thickness = 0.06,
        edge_thickness_px = 0.0,
        edge_height = 0.0,
        tint_color = 0x8899aa22, -- RRGGBBAA
        lens_distortion = 0.5,
        self_sample = 0.0,
        xray = 0,
        focus_light = 0.0,
        focus_light_color = 0xffffff00,
        frost = 0.0,
        frost_blur = 3.0,

        dark = {
            brightness = 0.82,
            contrast = 0.90,
            saturation = 0.80,
            vibrancy = 0.15,
            vibrancy_darkness = 0.0,
            adaptive_dim = 0.4,
            adaptive_boost = 0.0,
        },
        light = {
            brightness = 1.12,
            contrast = 0.92,
            saturation = 0.85,
            vibrancy = 0.12,
            vibrancy_darkness = 0.0,
            adaptive_dim = 0.0,
            adaptive_boost = 0.4,
        },

        layers = {
            enabled = false,
            mask_threshold = 0.136,
            mask_mode = "auto",
            mask_feather = 0.22,
            live_resample = true,
            live_resample_fps = 30,
            force_live_resample = false,
            manage_blur = true,
        },

        windows = {
            background_cache = true,
            live_resample = true,
            live_resample_fps = 100,
        },

        subsurfaces = {
            enabled = false,
            radius = -1,
        },
    })

    hg.preset(PRESET, PRESET_VALUES)

    hg.layer("settings-panel", {
        preset = PRESET,
        mask_threshold = 0.01,
        mask_mode = "auto",
        mask_feather = 0.0,
        live_resample = true,
        exclude = false,
    })

    hg.layer("app-drawer", {
        preset = PRESET,
        mask_threshold = 0.01,
        mask_mode = "auto",
        mask_feather = 0.0,
        live_resample = true,
        exclude = false,
    })

    hg.layer("quickshell-bar", {
        preset = PRESET,
        mask_threshold = 0.15,
        mask_mode = "auto",
        mask_feather = 0.4,
        live_resample = true,
        exclude = false,
    })

    hg.layer("music-player", {
        preset = PRESET,
        mask_threshold = 0.01,
        mask_mode = "auto",
        mask_feather = 0.0,
        live_resample = true,
        exclude = false,
    })
end

return { preset = PRESET, values = PRESET_VALUES }
