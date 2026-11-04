local home = os.getenv("HOME")
local hex = {}
local f = io.open(home .. "/.cache/wal/colors-hyprland")
if f then
    for line in f:lines() do
        local i, rgb = line:match("%$color(%d+)%s*=%s*0x%x%x(%x%x%x%x%x%x)")
        if i then hex[tonumber(i)] = rgb end
    end
    f:close()
end
local roles = io.open(home .. "/.config/hypr/state/color-roles.json")
local accent = tonumber(roles and roles:read("a"):match('"accent"%s*:%s*(%d+)') or 9)
if roles then roles:close() end
return {
    hex = hex,
    accent = accent,
    color = function(i, a) return "rgba(" .. (hex[i] or "8a8f98") .. (a or "ff") .. ")" end,
}
