#!/bin/bash
HYPR="$HOME/.config/hypr"
saved="$HYPR/state/color-roles-saved.json"
active="$HYPR/state/color-roles.json"
key="$(cat "$HYPR/state/color-theme" 2>/dev/null)"
[ "${key:-pywal}" = pywal ] && key="pywal:$(cat "$HOME/.cache/wal/wal" 2>/dev/null)"

[ -s "$saved" ] || jq -sc --arg k "$key" '{($k): (.[0] // {})}' "$active" > "$saved" 2>/dev/null || echo '{}' > "$saved"
case "$1" in
    set) f='.[$k][$r] = ($n | tonumber)' ;;
    reset) f='del(.[$k])' ;;
    *) f='.' ;;
esac
jq -c --arg k "$key" --arg r "$2" --arg n "${3:-0}" "$f" "$saved" > "$saved.tmp" && mv "$saved.tmp" "$saved"
jq -c --arg k "$key" '.[$k] // {}' "$saved" > "$active"

css="$HOME/.cache/wal/colors-waybar.css"
if [ -f "$css" ]; then
    slot="$(jq '.accent // 9' "$active" 2>/dev/null)"
    hex="$(sed -n "s/^@define-color color${slot:-9} \(#[0-9a-fA-F]*\);/\1/p" "$css")"
    sed -i '/^@define-color accent /d' "$css"
    printf '@define-color accent %s;\n' "$hex" >> "$css"
    s="$HOME/.config/waybar/style.css"
    [ -f "$s" ] && dd if="$s" of="$s" conv=notrunc status=none
fi
[ -n "$1" ] && hyprctl reload config-only >/dev/null 2>&1
exit 0
