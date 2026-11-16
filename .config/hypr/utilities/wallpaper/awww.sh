#!/bin/bash
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../paths.sh"
grep -qs awww-daemon "$STYLE/base/session.sh" || exit 0
if ! awww query >/dev/null 2>&1; then
    setsid -f awww-daemon </dev/null >/dev/null 2>&1
    for _ in $(seq 1 60); do awww query >/dev/null 2>&1 && break; sleep 0.05; done
fi
awww img "$@"
