#!/bin/bash
set -uo pipefail

. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/paths.sh"

call() {
    qs -p "$QS" ipc call "$@" >/dev/null 2>&1
}

# start the shared process if it isn't running, locked so two calls can't race
launch() (
    exec 9>"${XDG_RUNTIME_DIR:-/tmp}/quickshell-utilities.lock"
    flock -w 5 9 || exit 1
    qs ipc -p "$QS" show 2>/dev/null | grep -q '^target' && exit 0
    # 9>&- so the daemon doesn't keep the lock
    qs -n -p "$QS" --daemonize </dev/null >/dev/null 2>&1 9>&-
    for _ in $(seq 1 60); do
        qs ipc -p "$QS" show 2>/dev/null | grep -q '^target' && exit 0
        sleep 0.05
    done
    exit 1
)

case "${1:-}" in
    start)
        launch
        exit 0
        ;;
    stop)
        qs kill -p "$QS" </dev/null >/dev/null 2>&1
        # kill returns before the process is gone
        for _ in $(seq 1 40); do
            qs list -p "$QS" 2>/dev/null | grep -q '^Instance' || break
            sleep 0.05
        done
        exit 0
        ;;
    restart)
        "$0" stop
        "$0" start
        exit 0
        ;;
    "")
        echo "usage: shells.sh start|stop|restart | <utility> [call [args...]]" >&2
        exit 2
        ;;
esac

target="$1"
shift
[ $# -gt 0 ] || set -- toggle

call "$target" "$@" && exit 0
[ "$1" = close ] && exit 0

[ "$1" = toggle ] && set -- open "${@:2}"
launch || exit 1
for _ in $(seq 1 20); do
    call "$target" "$@" && exit 0
    sleep 0.05
done
exit 1
