local ok, S = pcall(require, "settings")
if not ok or type(S) ~= "table" then S = {} end

if S.config then
    local core = {}
    for k, v in pairs(S.config) do
        if k ~= "plugin" then core[k] = v end
    end
    hl.config(core)
end

local A = S.animation
if A and A.curve then
    local mult = math.max(0.1, tonumber(A.speed) or 1)
    local windowStyle = A.window or "popin 90%"
    local workspaceStyle = A.workspace or "slide"
    hl.curve("panel", { type = "bezier", points = { { A.curve[1], A.curve[2] }, { A.curve[3], A.curve[4] } } })
    local leaves = {
        { "windows", 4, windowStyle },
        { "windowsOut", 3.5, windowStyle },
        { "windowsMove", 3 },
        { "fade", 4 },
        { "border", 6 },
        { "workspaces", 4, workspaceStyle },
        { "specialWorkspace", 4, workspaceStyle },
        { "layers", 3, "popin 80%" },
    }
    for _, leaf in ipairs(leaves) do
        hl.animation({ leaf = leaf[1], enabled = true, speed = leaf[2] / mult, bezier = "panel", style = leaf[3] })
    end
end

local B = S.border
if B and B.gradient then
    local wal = require("wal")
    local PALETTES = {
        accent = { 9, 13 },
        ocean = { 9, 12, 14 },
        ember = { 1, 3 },
        aurora = { 2, 6, 4 },
        sunset = { 1, 5, 13 },
        glow = { 9, 15 },
    }
    local stops = {}
    for _, i in ipairs(PALETTES[B.palette] or PALETTES.accent) do
        if wal.hex[i] then stops[#stops + 1] = wal.color(i) end
    end
    if #stops == 1 then stops[2] = stops[1] end
    if #stops >= 2 then
        hl.config({ general = { col = { active_border = { colors = stops, angle = B.angle or 45 } } } })
    end
end

hl.layer_rule({ name = "style-transition-noanim", match = { namespace = "style-transition" }, no_anim = true })
local held, hold = pcall(dofile, (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/style-transition.lua")
if held then
    hl.config({ general = hold })
    hl.animation({ leaf = "layersOut", enabled = false })
    hl.animation({ leaf = "fadeLayersOut", enabled = false })
end

if S.mice and S.config and S.config.input and S.config.input.sensitivity ~= nil then
    for _, name in ipairs(S.mice) do
        hl.device({ name = name, sensitivity = S.config.input.sensitivity })
    end
end
