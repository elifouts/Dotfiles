#!/bin/bash
set -uo pipefail

# usage: osd.sh vol-up|vol-down|vol-mute|mic-mute|bright-up|bright-down|caps|play|next|prev

DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

case "${1:-}" in
    bright-up | bright-down)
        out="$(brightnessctl -m -n1 set "10%$([[ $1 == bright-up ]] && echo + || echo -)")" || exit 1
        pct="$(cut -d, -f4 <<<"$out" | tr -d '%')"
        "$DIR/shells.sh" osd brightness "$(awk -v p="$pct" 'BEGIN { print p / 100 }')"
        ;;
    # the osd does these itself and watches the real state, doing them out here raced when spammed
    vol-up | vol-down | vol-mute | mic-mute | caps | play | next | prev)
        "$DIR/shells.sh" osd act "$1"
        ;;
    *)
        echo "unknown action: ${1:-}" >&2
        exit 2
        ;;
esac
