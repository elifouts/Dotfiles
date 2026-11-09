#!/bin/bash
set -uo pipefail

. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../paths.sh"
QML="$UTIL/session/TransitionShared.qml"
OLD="${XDG_RUNTIME_DIR:-/tmp}/style-transition.json"
HOLD="${XDG_RUNTIME_DIR:-/tmp}/style-transition.lua"

call() { qs -p "$QML" ipc call transition "$@" 2>/dev/null; }
reserved() { hyprctl -j monitors | jq -c 'map({(.name): .reserved}) | add'; }
gap() { hyprctl -j getoption "general:$1" | jq -r '(.css // .custom // "\(.int)") | split(" ") | "\(.[0]), right = \(.[1] // .[0]), bottom = \(.[2] // .[0]), left = \(.[3] // .[1] // .[0])"'; }
drawn() { hyprctl -j layers | jq -e '[.[].levels["0"] // [] | map(select(.namespace != "style-transition")) | length > 0] | all' >/dev/null; }

begin() {
    printf 'return { gaps_in = { top = %s }, gaps_out = { top = %s } }\n' "$(gap gaps_in)" "$(gap gaps_out)" > "$HOLD"
    reserved > "$OLD"
    qs kill -p "$QML" </dev/null >/dev/null 2>&1
    QSG_USE_SIMPLE_ANIMATION_DRIVER=1 qs -n -p "$QML" --daemonize </dev/null >/dev/null 2>&1
    for _ in $(seq 1 40); do
        [ "$(call covered)" = true ] && break
        sleep 0.02
    done
    call hold "$(cat "$OLD")"
    hyprctl eval 'package.loaded.overrides=nil require("overrides")' >/dev/null 2>&1
}

reveal() {
    local now
    for _ in $(seq 1 60); do
        now="$(reserved)"
        drawn && [ "$now" != "$(cat "$OLD")" ] && break
        sleep 0.02
    done
    call hold "$(jq -nc --argjson old "$(cat "$OLD")" --argjson now "$(reserved)" \
        '$old | with_entries(.key as $m | .value |= [range(length) as $i | $old[$m][$i] as $o | ($now[$m][$i] - $o) as $bar | ($o - $bar) | if . < 0 then 0 else . end])')"
    sleep 0.12
    call hold '{}'
    rm -f "$HOLD" "$OLD"
    hyprctl reload config-only >/dev/null 2>&1
    call reveal
}

case "${1:-}" in
    begin) begin ;;
    reveal) reveal ;;
    *) echo "usage: transition.sh begin|reveal" >&2; exit 2 ;;
esac
exit 0
