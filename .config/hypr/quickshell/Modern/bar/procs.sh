#!/bin/sh
for p; do
    c=$(tr '\0' '\037' < "/proc/$p/cmdline")
    s=$(ps --ppid "$p" -o pid=,tty=,comm= | awk '$2 != "?" && $3 ~ /^(bash|zsh|fish|sh|dash)$/ { print $1; exit }')
    d=
    r=
    if [ -n "$s" ]; then
        l=$(pgrep -P "$s" | tail -1)
        d=$(readlink "/proc/${l:-$s}/cwd")
        [ -n "$l" ] && r=$(tr '\0' '\037' < "/proc/$l/cmdline")
    fi
    printf '%s\036%s\036%s\n' "$c" "$d" "$r"
done
