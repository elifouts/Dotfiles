#!/bin/bash
set -uo pipefail

# usage: capture.sh shot|rec region|window|screen | stop

STATE="${XDG_RUNTIME_DIR:-/tmp}/capture-rec"
SHOTS="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
VIDEOS="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
stamp="$(date +%Y-%m-%d_%H-%M-%S)"

note() { notify-send -a Capture -i "$3" "$1" "$2"; }

thumb() {
    local t="${XDG_CACHE_HOME:-$HOME/.cache}/capture-thumb.png"
    ffmpeg -y -loglevel error -i "$1" -frames:v 1 -vf scale=256:-1 "$t" 2>/dev/null && echo "$t" || echo video-x-generic
}

focused_monitor() {
    hyprctl -j monitors | jq -r '.[] | select(.focused) | .name'
}

windows() {
    local ws
    ws="$(hyprctl -j monitors | jq '[.[].activeWorkspace.id]')"
    hyprctl -j clients | jq -r --argjson ws "$ws" \
        '.[] | select(.mapped and (.workspace.id as $w | $ws | index($w))) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

area() {
    local g
    case "$1" in
        region) g="$(slurp -d)" ;;
        window) g="$(windows | slurp -r)" ;;
    esac
    [ -n "$g" ] && echo "$g"
}

shot() {
    local mode="$1" geo out="$SHOTS/shot-$stamp.png"
    mkdir -p "$SHOTS"
    if [ "$mode" = screen ]; then
        grim -o "$(focused_monitor)" "$out" || return 1
    else
        geo="$(area "$mode")" || return 0
        grim -g "$geo" "$out" || return 1
    fi
    wl-copy < "$out"
    note "Screenshot saved" "$out" "$out"
}

record() {
    local mode="$1" geo out="$VIDEOS/rec-$stamp.mp4" args=()
    if [ "$mode" = screen ]; then
        args=(-o "$(focused_monitor)")
    else
        geo="$(area "$mode")" || return 0
        args=(-g "$geo")
    fi
    mkdir -p "$VIDEOS"
    date +%s > "$STATE"
    wf-recorder "${args[@]}" -f "$out" >/dev/null 2>&1
    rm -f "$STATE"
    [ -s "$out" ] && note "Recording saved" "$out" "$(thumb "$out")"
}

case "${1:-}" in
    shot) shot "${2:?mode}" ;;
    rec)
        pkill -INT -x wf-recorder && exit 0
        record "${2:?mode}"
        ;;
    stop) pkill -INT -x wf-recorder; exit 0 ;;
    *) echo "usage: capture.sh shot|rec region|window|screen | stop" >&2; exit 2 ;;
esac
