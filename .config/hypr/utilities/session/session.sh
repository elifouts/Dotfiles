#!/bin/bash
set -uo pipefail

. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../paths.sh"

case "${1:-}" in
    start)
        "$UTIL/session/shells.sh" start
        [ -x "$STYLE/base/session.sh" ] && "$STYLE/base/session.sh"
        grep -qs pypr "$STYLE/base/session.sh" || { pkill -f "hypr/utilities/pypr/pypr\.sh"; pkill -f "hypr/utilities/pypr/pypr\.py"; }
        ;;
    stop)
        "$UTIL/session/shells.sh" stop
        pkill -x waybar
        pkill -x awww-daemon
        ;;
    *)
        echo "usage: session.sh start|stop" >&2
        exit 2
        ;;
esac
exit 0
