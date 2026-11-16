#!/bin/bash
HYPR="$HOME/.config/hypr"
RUN="${XDG_RUNTIME_DIR:-/tmp}/desk"

greet() {
    clear
    printf '\e[2m%s@%s  ·  %s\e[0m\n' "$USER" "$(cat /proc/sys/kernel/hostname)" "$(. /etc/os-release; echo "$NAME")"
    printf '\e[2mlast login  %s\e[0m\n' "$(date '+%a %d %b %y  %H:%M')"
    printf 'ready.\n'
}

held() {
    local t
    t="$(stat -c %Y "$RUN/.keep" 2>/dev/null)" && [ $(($(date +%s) - t)) -lt 30 ]
}

hide() {
    rm -f "$RUN/$1" "$RUN/look/$1" "$RUN/sock/$1"
    pkill -f "^/bin/bash .*/desk\.sh loop $1$"
    pkill -f "^[^ ]*kitty \+kitten panel .*--app-id=desk-$1(-frame)? "
}

loop() {
    local geo out x y w h pad size bg alpha font look id sw sh
    geo="$(cat "$RUN/$1" 2>/dev/null)"
    read -r out x y w h pad <<<"$geo"
    id="desk-$1"
    [ "${pad:-0}" = 0 ] && pad=2 || id="$id-frame"
    read -r sw sh < <(hyprctl monitors -j | jq -r --arg o "$out" '.[] | select(.name == $o) | .scale as $k | [.width, .height] as $s | (if .transform % 2 == 1 then [$s[1], $s[0]] else $s end) | map(. / $k | floor) | "\(.[0]) \(.[1])"' 2>/dev/null)
    look="$HYPR/$(cut -d/ -f1 "$HYPR/state/profile")/starship.toml"
    [ -f "$look" ] || look="$HOME/.config/starship.toml"
    while [ -n "$geo" ] && [ "$(cat "$RUN/$1" 2>/dev/null)" = "$geo" ]; do
        read -r size bg alpha font <"$RUN/look/$1"
        rm -f "$RUN/sock/$1"
        kitten panel --app-id="$id" --edge=none --layer=background --output-name="$out" --focus-policy=on-demand \
            --margin-left="$x" --margin-top="$y" --margin-right="$((${sw:-$((x + w))} - x - w))" --margin-bottom="$((${sh:-$((y + h))} - y - h))" --listen-on="unix:$RUN/sock/$1" \
            -o allow_remote_control=socket-only -o background="$bg" -o background_opacity="$alpha" -o dynamic_background_opacity=yes -o font_size="$size" ${font:+-o "font_family=$font"} \
            -o cursor_shape=block -o cursor_blink_interval=0 -o cursor_trail=0 -o window_padding_width="$((pad * 3 / 4))" \
            -o confirm_os_window_close=0 -o enable_audio_bell=no \
            env NOFETCH=1 STARSHIP_CONFIG="$look" bash -c "cd; $(declare -f greet); greet; exec bash -i" >/dev/null 2>&1
        sleep 0.4
    done
}

case "${1:-}" in
    show)
        key="$2" geo="${*:3:6}" look="${*:9}"
        mkdir -p "$RUN/look" "$RUN/sock"
        if [ "$(cat "$RUN/$key" 2>/dev/null)" = "$geo" ] && pgrep -f "^/bin/bash .*/desk\.sh loop $key$" >/dev/null; then
            touch "$RUN/$key"
            [ "$(cat "$RUN/look/$key" 2>/dev/null)" = "$look" ] && exit 0
            printf '%s' "$look" > "$RUN/look/$key"
            read -r size bg alpha font <<<"$look"
            kitten @ --to "unix:$RUN/sock/$key" load-config -o font_size="$size" -o background="$bg" ${font:+-o "font_family=$font"} >/dev/null 2>&1
            kitten @ --to "unix:$RUN/sock/$key" set-background-opacity "$alpha" >/dev/null 2>&1
            exit 0
        fi
        hide "$key"
        printf '%s' "$look" > "$RUN/look/$key"
        printf '%s' "$geo" > "$RUN/$key"
        setsid -f "$HYPR/utilities/desk.sh" loop "$key" </dev/null >/dev/null 2>&1 ;;
    hide) held || hide "$2" ;;
    drop)
        mkdir -p "$RUN"; mark="$RUN/.drop-$2"; touch "$mark"; sleep 1
        [ "$RUN/$2" -nt "$mark" ] || held || hide "$2"
        rm -f "$mark" ;;
    loop) loop "$2" ;;
    stop) held || for f in "$RUN"/*; do [ -f "$f" ] && hide "${f##*/}"; done ;;
    hold) mkdir -p "$RUN"; touch "$RUN/.keep" ;;
    release)
        [ -e "$RUN/.keep" ] || exit 0
        sleep 1.5
        for f in "$RUN"/*; do [ -f "$f" ] && ! [ "$f" -nt "$RUN/.keep" ] && hide "${f##*/}"; done
        rm -f "$RUN/.keep" ;;
    *) echo "usage: desk.sh show <key> <output> <x> <y> <w> <h> <pad> <pt> <bg> <alpha> [font] | hide <key> | drop <key> | stop | hold | release" >&2; exit 2 ;;
esac
