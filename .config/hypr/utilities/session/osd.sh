#!/bin/bash
set -uo pipefail

DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

case "${1:-}" in
    bright-up | bright-down)
        out="$(brightnessctl -m -n1 set "10%$([[ $1 == bright-up ]] && echo + || echo -)")" || exit 1
        pct="$(cut -d, -f4 <<<"$out" | tr -d '%')"
        "$DIR/shells.sh" osd brightness "$(awk -v p="$pct" 'BEGIN { print p / 100 }')"
        ;;
    vol-up | vol-down | vol-mute | mic-mute | caps | play | next | prev)
        "$DIR/shells.sh" osd act "$1"
        ;;
    *)
        echo "unknown action: ${1:-}" >&2
        exit 2
        ;;
esac
