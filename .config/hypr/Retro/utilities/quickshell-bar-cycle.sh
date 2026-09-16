#!/bin/sh
set -eu
if pgrep -f 'quickshell.*bar.qml' >/dev/null 2>&1; then
    exec quickshell --path "$HOME/.config/hypr/utilities/quickshell/bar.qml" ipc call bar cycle
else
    exec quickshell --path "$HOME/.config/hypr/utilities/quickshell/bar.qml" --no-duplicate --daemonize
fi