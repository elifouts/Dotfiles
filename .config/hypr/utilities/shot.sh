#!/bin/bash
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/paths.sh"

mode="${1:-region}"
dir="$HOME/Screenshots"
frag="$(hyprctl getoption decoration:screen_shader -j | jq -r '.str // empty')"
crt="$STYLE/base/shot.py"

if [ -z "$frag" ] || [ "$frag" = "[[EMPTY]]" ] || [ ! -f "$frag" ] || [ ! -f "$crt" ]; then
    [ "$mode" = output ] && exec hyprshot -m active -m output -o "$dir"
    exec hyprshot -m "$mode" -o "$dir"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mons="$(hyprctl monitors -j | jq '[.[] | .scale as $k | (if .transform % 2 == 1 then [.height, .width] else [.width, .height] end) as $s
    | {name, x, y, scale, focused, w: ($s[0] / $k | floor), h: ($s[1] / $k | floor), ws: .activeWorkspace.id}]')"
for m in $(jq -r '.[].name' <<<"$mons"); do grim -o "$m" "$tmp/$m.png" & done
wait

case "$mode" in
    output) geo="$(jq -r '.[] | select(.focused) | "\(.x),\(.y) \(.w)x\(.h)"' <<<"$mons")" ;;
    window) geo="$(hyprctl clients -j | jq -r --argjson ws "$(jq '[.[].ws]' <<<"$mons")" \
        '.[] | select(.workspace.id as $w | $ws | index($w)) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | slurp -r)" || exit 0 ;;
    *) geo="$(slurp -d)" || exit 0 ;;
esac

read -r gx gy gw gh <<<"$(tr ',x' '  ' <<<"$geo")"
read -r name mx my k <<<"$(jq -r --argjson x "$gx" --argjson y "$gy" \
    '.[] | select($x >= .x and $x < .x + .w and $y >= .y and $y < .y + .h) | "\(.name) \(.x) \(.y) \(.scale)"' <<<"$mons" | head -1)"
[ -n "$name" ] || exit 1

mkdir -p "$dir"
out="$dir/$(date +%Y-%m-%d-%H%M%S)_hyprshot.png"
python3 -I "$crt" "$tmp/$name.png" "$tmp/crt.png" "$frag" || exit 1
crop="$(awk -v k="$k" -v x="$((gx - mx))" -v y="$((gy - my))" -v w="$gw" -v h="$gh" 'BEGIN { printf "%dx%d+%d+%d", w * k, h * k, x * k, y * k }')"
magick "$tmp/crt.png" -crop "$crop" +repage "$out"
wl-copy --type image/png <"$out"
notify-send -a Hyprshot -i "$out" "Screenshot saved" "with the crt on" 2>/dev/null
