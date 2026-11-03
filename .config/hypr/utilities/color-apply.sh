#!/bin/bash
set -uo pipefail

. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/paths.sh"
STATE="$HYPR/state/color-theme"
SCHEMES="$HOME/.config/wal/colorschemes"

theme="${1:-}"
if [ -n "$theme" ]; then
    printf '%s\n' "$theme" > "$STATE"
else
    theme="$(cat "$STATE" 2>/dev/null || true)"
    theme="${theme:-pywal}"
fi

wallpaper="${2:-}"
[ -n "$wallpaper" ] || wallpaper="$(cat "$HOME/.cache/wallpaper-picker/current" 2>/dev/null || cat "$HOME/.cache/wal/wal" 2>/dev/null || true)"

if [ "$theme" != pywal ] && [ -f "$SCHEMES/$theme.json" ]; then
    flags=(-n)
    [ "${theme%%/*}" = light ] && flags+=(-l)
    wal --theme "$SCHEMES/$theme.json" "${flags[@]}" >/dev/null || exit 1
elif [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
    wal -i "$wallpaper" -n --cols16 >/dev/null || exit 1
else
    echo "No wallpaper to derive colors from." >&2
    exit 1
fi

[ -f "$wallpaper" ] && printf '%s' "$wallpaper" > "$HOME/.cache/wal/wal"

"$HYPR/utilities/color-roles.sh"
cat ~/.cache/wal/colors-kitty.conf > ~/.config/kitty/current-theme.conf
pywalfox update >/dev/null 2>&1 || true

walc() { awk -v k="$1" 'match($0, "^" k "=\47(.*)\47", a) { print a[1] }' ~/.cache/wal/colors.sh; }
mkdir -p "$(readlink -m "$HOME/.config/cava")"
cat >"$HOME/.config/cava/config" <<CAVA
[general]
framerate = 60
autosens = 1
lower_cutoff_freq = 50
higher_cutoff_freq = 12000
bar_width = 1
bar_spacing = 1

[output]
channels = mono
mono_option = average

[color]
horizontal_gradient = 1
horizontal_gradient_count = 5
horizontal_gradient_color_1 = '$(walc color12)'
horizontal_gradient_color_2 = '$(walc color14)'
horizontal_gradient_color_3 = '$(walc color10)'
horizontal_gradient_color_4 = '$(walc color11)'
horizontal_gradient_color_5 = '$(walc color13)'

[smoothing]
noise_reduction = 72
CAVA
# USR1 reloads everything, USR2 colors only (i think)
pkill -USR1 cava 2>/dev/null || true

hyprctl reload config-only >/dev/null 2>&1 || true
