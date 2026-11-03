#!/bin/bash
# usage: session.sh start|stop
# start runs the style's daemons, stop kills anything any style starts
set -uo pipefail

. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/paths.sh"

case "${1:-}" in
    start)
        "$UTIL/shells.sh" start
        [ -x "$STYLE/base/session.sh" ] && "$STYLE/base/session.sh"
        # pypr outlives style switches (restarting it lost the scratchpads), only a style that doesn't use it stops it
        grep -qs pypr "$STYLE/base/session.sh" || { pkill -f "hypr/utilities/pypr\.sh"; pkill -f "hypr/utilities/pypr\.py"; }
        ;;
    stop)
        "$UTIL/shells.sh" stop
        pkill -x waybar
        # only styles that paint with awww want it, space draws its own sky
        pkill -x awww-daemon
        ;;
    *)
        echo "usage: session.sh start|stop" >&2
        exit 2
        ;;
esac
exit 0
