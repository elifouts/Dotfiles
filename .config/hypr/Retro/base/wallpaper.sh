#!/bin/bash
set -o pipefail
HYPR="$HOME/.config/hypr"
cache="$HOME/.cache/retro-wall"

if [ "${1:-}" = --apply ]; then
    src="$(cat "$HOME/.cache/wallpaper-picker/current" 2>/dev/null)"
    out="$("$0" "$src")" || exit 1
    "$HYPR/utilities/wallpaper/awww.sh" "$out" --transition-type fade --transition-duration .4
    exit 0
fi

src="${1:?image}"
[ -f "$src" ] || exit 1
. "$HOME/.cache/wal/colors.sh"
slot="$(jq '.accent // 9' "$HYPR/state/color-roles.json" 2>/dev/null || echo 9)"
acc="$(eval echo "\$color${slot:-9}")"
opts="$(jq -r '.filter // {} | [(.on != false), (.dither // "bayer"), (.pixel // 2), (.levels // 6), (.contrast // 0.5), (.bright // 0.4), (.tone // "lines")] | @tsv' "$HYPR/state/settings.json" 2>/dev/null)"
IFS=$'\t' read -r on dither pixel levels contrast bright tone <<<"${opts:-true	bayer	2	6	0.5	0.4	lines}"

if [ "$on" = false ]; then
    out="$cache/black.png"
    [ -f "$out" ] || { mkdir -p "$cache"; magick -size 64x64 xc:'#000000' "$out"; }
else
    key="$(printf '%s ' "$src" "$(stat -c %Y "$src")" "$background" "$acc" "$color8" $opts | md5sum | cut -c1-16)"
    out="$cache/$key.png"
fi

if [ ! -f "$out" ]; then
    mkdir -p "$cache"
    tmp="$out.$$.png"
    w=$((1920 / pixel)) h=$((1080 / pixel))
    sig=$(awk -v c="$contrast" 'BEGIN { printf "%.2f", c * 8 }')
    dim=$(awk -v b="$bright" 'BEGIN { printf "%d", (1 - b) * 85 }')
    case "$dither" in
        bayer) dith=(-ordered-dither "o4x4,$levels") ;;
        fine) dith=(-ordered-dither "o8x8,$levels") ;;
        halftone) dith=(-ordered-dither "h6x6a,$levels") ;;
        diffuse) dith=(-dither FloydSteinberg -posterize "$levels") ;;
        *) dith=(+dither -posterize "$levels") ;;
    esac
    [ "$sig" = 0.00 ] && curve=() || curve=(-sigmoidal-contrast "${sig}x50%")
    hi=$(awk -v c="$contrast" 'BEGIN { printf "%d", 30 - c * 24 }')
    case "$tone" in
        lines)
            body=(-colorspace gray -blur 0x1 -canny "0x1+$((hi / 3))%+${hi}%"
                \( xc:"$background" \( xc:"$acc" -fill "$background" -colorize "$dim%" \) +append -resize 256x1! \) -clut) ;;
        source)
            body=("${curve[@]}" "${dith[@]}" -fill "$background" -colorize "$dim%") ;;
        palette)
            pal="$cache/palette-$$.png"
            magick xc:"$background" xc:"$color1" xc:"$color2" xc:"$color3" xc:"$color4" xc:"$color5" xc:"$color6" xc:"$color7" xc:"$color8" xc:"$acc" +append "$pal"
            [ "$dither" = none ] && d=+dither || d="-dither FloydSteinberg"
            body=("${curve[@]}" -fill "$background" -colorize "$dim%" $d -remap "$pal") ;;
        *)
            body=(-colorspace gray -contrast-stretch 2%x1% "${curve[@]}" "${dith[@]}"
                \( xc:"$background" xc:"$color8" \( xc:"$acc" -fill "$background" -colorize "$dim%" \) +append -resize 256x1! \) -clut) ;;
    esac
    magick "$src" -auto-orient -resize "${w}x${h}^" "${body[@]}" -filter point -resize "${pixel}00%" -strip "$tmp" && mv -f "$tmp" "$out"
    ok=$?
    rm -f "$tmp" "$cache"/palette-$$.png
    [ $ok = 0 ] || exit 1
    ls -t "$cache"/*.png 2>/dev/null | tail -n +61 | xargs -r rm -f
fi
ln -sfn "$out" "$cache/current"
printf '%s\n' "$out"
