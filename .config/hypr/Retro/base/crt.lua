local runtime = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/retro-crt/"
local here = debug.getinfo(1, "S").source:sub(2):match("(.*/)")

return function(wal)
    local ok, S = pcall(require, "settings")
    local c = (ok and type(S) == "table" and S.crt) or {}
    if c.on == false then return hl.config({ decoration = { screen_shader = "" }, debug = { damage_tracking = 2 }, cursor = { no_hardware_cursors = 2 } }) end
    local bend = (c.bend or 0) * 0.08
    local hex = "#" .. (wal.hex[wal.accent] or "33ff66")
    local r, g, b = tonumber(hex:sub(2, 3), 16) / 255, tonumber(hex:sub(4, 5), 16) / 255, tonumber(hex:sub(6, 7), 16) / 255
    local defs = string.format(
        "#define TINT vec3(%.3f, %.3f, %.3f)\n#define MONO %.2f\n#define LINES %.2f\n#define GLOW %.2f\n#define VIGNETTE %.2f\n#define GRAIN %.3f\n#define BEND %.3f\n#define CURVED %d\n#define ROUND %.3f\n",
        r, g, b, c.mono or 0.85, c.lines or 0.35, c.glow or 0.5, c.vignette or 0.5, (c.grain or 0.4) * 0.06, bend, bend > 0 and 1 or 0, c.corners or 0.5)
    local f = io.open(here .. "crt.frag")
    if not f then return end
    local src = f:read("a"):gsub("// defs\n", defs)
    f:close()
    local sum = 0
    for i = 1, #src do sum = (sum * 31 + src:byte(i)) % 2147483647 end
    local path = runtime .. sum .. ".frag"
    if not io.open(path) then
        os.execute("mkdir -p '" .. runtime .. "' && rm -f '" .. runtime .. "'*.frag")
        local out = io.open(path, "w")
        out:write(src)
        out:close()
    end
    hl.config({ decoration = { screen_shader = path }, debug = { damage_tracking = bend > 0 and 1 or 2 }, cursor = { no_hardware_cursors = bend > 0 and 1 or 2 } })
end
