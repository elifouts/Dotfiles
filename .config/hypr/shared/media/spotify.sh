#!/bin/bash
# opens spotify from its pypr scratchpad, or as a normal window without pypr
c=$(hyprctl clients -j | jq -c '[.[] | select(.class | test("^spotify$"; "i"))][0] // empty')
if [ "${1:-}" = toggle ] || [ -z "$c" ] || echo "$c" | jq -e '.workspace.name | startswith("special")' >/dev/null; then
    pypr "${1:-show}" spotify 2>/dev/null && exit 0
fi
if [ -n "$c" ]; then
    a=$(echo "$c" | jq -r .address)
    # lua dispatch if hyprland.lua is in use
    if [ -f "$HOME/.config/hypr/hyprland.lua" ]; then
        hyprctl dispatch "hl.dsp.focus({ window = \"address:$a\" })" >/dev/null
    else
        hyprctl dispatch focuswindow "address:$a" >/dev/null
    fi
elif command -v spotify-launcher >/dev/null; then
    exec spotify-launcher
else
    exec spotify
fi
