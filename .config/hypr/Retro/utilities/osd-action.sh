#!/bin/sh
set -eu
osd="$HOME/.config/hypr/utilities/quickshell/osd.qml"
state_file="$HOME/.cache/hypr/osd-state"
exec 9>"$HOME/.cache/hypr/osd.lock"
flock 9
notify() {
    mkdir -p "$HOME/.cache/hypr"
    tmp="$state_file.tmp.$$"
    printf '%s %s\n' "$1" "$2" > "$tmp"
    mv -f "$tmp" "$state_file"
    quickshell ipc --path "$HOME/.config/hypr/utilities/quickshell/osd.qml" call osd refresh >/dev/null 2>&1 || true
}
volume_value() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{ printf "%d", $2 * 100 }'
}
media_notify() {
    status=$(playerctl status 2>/dev/null | tr '[:lower:]' '[:upper:]' || printf 'PAUSED')
    track=$(playerctl metadata --format '{{title}} - {{artist}}' 2>/dev/null || printf 'No track')
    art=$(playerctl metadata --format '{{mpris:artUrl}}' 2>/dev/null || true)
    mkdir -p "$HOME/.cache/hypr"
    tmp="$state_file.tmp.$$"
    printf 'media %s %s\t%s\n' "$status" "$track" "$art" > "$tmp"
    mv -f "$tmp" "$state_file"
    quickshell ipc --path "$HOME/.config/hypr/utilities/quickshell/osd.qml" call osd refresh >/dev/null 2>&1 || true
}
case "${1:-}" in
    volume-up)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
        notify volume "$(volume_value)"
        ;;
    volume-down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        notify volume "$(volume_value)"
        ;;
    volume-mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        if wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q MUTED; then notify volume 0; else notify volume "$(volume_value)"; fi
        ;;
    brightness-up)
        brightnessctl set 5%+ >/dev/null
        notify brightness "$(brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,"",$4); printf "%d", $4}')"
        ;;
    brightness-down)
        brightnessctl set 5%- >/dev/null
        notify brightness "$(brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,"",$4); printf "%d", $4}')"
        ;;
    media-play)
        playerctl play-pause
        sleep 0.05
        media_notify
        ;;
    media-next)
        playerctl next
        sleep 0.05
        media_notify
        ;;
    media-prev)
        playerctl previous
        sleep 0.05
        media_notify
        ;;
    caps)
        caps_state="$HOME/.cache/hypr/caps-lock-state"
        if [[ -f "$caps_state" ]]; then
            current=$(cat "$caps_state")
        else
            current=$(hyprctl devices -j 2>/dev/null | jq -r 'first(.keyboards[]? | select(.main == true) | .capsLock) // false' 2>/dev/null || printf 'false')
        fi
        if [[ "$current" == "true" ]]; then next=false; else next=true; fi
        printf '%s\n' "$next" > "$caps_state"
        notify caps "$([[ "$next" == "true" ]] && printf 'ON' || printf 'OFF')"
        ;;
    *)
        exit 2
        ;;
esac
