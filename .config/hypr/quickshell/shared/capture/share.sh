#!/bin/bash
set -uo pipefail

RUN="${XDG_RUNTIME_DIR:-/tmp}"
REQ="$RUN/share-request"
ANS="$RUN/share-answer"
HY="$(readlink -f "$HOME/.config/hypr")"

answer() { printf '%s' "$1" > "$ANS.tmp" && mv "$ANS.tmp" "$ANS"; }

handle() {
    local hex="${1#0x}" list entry wa
    list="$(tail -n +2 "$REQ")"
    while [[ "$list" == *"[HA>]"* ]]; do
        entry="${list%%"[HA>]"*}"
        list="${list#*"[HA>]"}"
        wa="${entry##*"[HE>]"}"
        wa="${wa#0x}"
        if [ "$wa" = "$hex" ] || [ "$wa" = "$((16#$hex))" ]; then
            echo "${entry%%"[HC>]"*}"
            return 0
        fi
    done
    return 1
}

pick() {
    local sel="" o x y w h mx my ws addr id
    case "$1" in
        screen)
            if [ "$(hyprctl -j monitors | jq length)" -gt 1 ]; then o="$(slurp -o -f %o)" || o=""
            else o="$(hyprctl -j monitors | jq -r '.[0].name')"; fi
            [ -n "$o" ] && sel="screen:$o"
            ;;
        region)
            read -r o x y w h < <(slurp -d -f '%o %x %y %w %h') || true
            if [ -n "${o:-}" ]; then
                read -r mx my < <(hyprctl -j monitors | jq -r --arg o "$o" '.[] | select(.name == $o) | "\(.x) \(.y)"')
                sel="region:$o@$((x - mx)),$((y - my)),$w,$h"
            fi
            ;;
        window)
            ws="$(hyprctl -j monitors | jq '[.[].activeWorkspace.id]')"
            addr="$(hyprctl -j clients | jq -r --argjson ws "$ws" \
                '.[] | select(.mapped and (.workspace.id as $w | $ws | index($w))) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1]) \(.address)"' \
                | slurp -r -f %l)" || addr=""
            [ -n "$addr" ] && id="$(handle "$addr")" && sel="window:$id"
            ;;
    esac
    answer "$sel"
}

picker() {
    local flags="" sel i
    [[ " $* " == *" --allow-token "* ]] && flags=r
    local open=""
    if qs ipc -p "$HY/quickshell" show 2>/dev/null | grep -q '^target space'; then
        open="qs ipc -p $HY/quickshell call space open capture"
    elif [ "$(cat "$HY/state/bar" 2>/dev/null)" = quickshell ] \
        && qs ipc -p "$HY/quickshell" show 2>/dev/null | grep -q '^target bar'; then
        open="qs ipc -p $HY/quickshell call bar island capture"
    fi
    [ -n "$open" ] || exec hyprland-share-picker "$@"
    rm -f "$ANS"
    trap ': > "$REQ"; rm -f "$ANS"' EXIT
    printf '1\n%s' "${XDPH_WINDOW_SHARING_LIST:-}" > "$REQ"
    $open >/dev/null 2>&1
    for ((i = 0; i < 1200; i++)); do
        [ -e "$ANS" ] && break
        sleep 0.1
    done
    sel="$(cat "$ANS" 2>/dev/null)"
    [ -n "$sel" ] || exit 1
    echo "[SELECTION]$flags/$sel"
}

case "${1:-}" in
    pick) pick "${2:?mode}" ;;
    cancel) answer "" ;;
    *) picker "$@" ;;
esac
