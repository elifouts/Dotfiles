#!/bin/bash
set -euo pipefail
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../paths.sh"

selected_wallpaper="${1:?usage: wallpaper-apply.sh <image> [output,output...]}"

show() { "$UTIL/wallpaper/awww.sh" ${2:+-o "$2"} "$1" --transition-type "${WALLPAPER_TRANSITION:-none}" --transition-duration .5 || true; }
if [ -x "$STYLE/base/wallpaper.sh" ]; then
    [ -n "${COLORS_DONE:-}" ] || WALL_SKIP=1 "$UTIL/colors/color-apply.sh" "" "$selected_wallpaper"
    show "$("$STYLE/base/wallpaper.sh" "$selected_wallpaper" || echo "$selected_wallpaper")" "${2:-}"
else
    show "$selected_wallpaper" "${2:-}"
    [ -n "${COLORS_DONE:-}" ] || "$UTIL/colors/color-apply.sh" "" "$selected_wallpaper"
fi

mkdir -p ~/.cache/wallpaper-picker && printf "%s\n" "$selected_wallpaper" > ~/.cache/wallpaper-picker/current
cp -r "$selected_wallpaper" "$HOME/wallpapers/pywallpaper.jpg"
"$QS/style/home/home-wall.sh" >/dev/null 2>&1 &

[ -n "${HYPR_SETTINGS_NO_RECORD:-}" ] || python3 "$UTIL/settings/hypr-settings.py" set "wallpaper.path=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$selected_wallpaper")" >/dev/null 2>&1 || true
