#!/bin/sh
set -eu
quickshell --path "$HOME/.config/hypr/utilities/quickshell/bar.qml" ipc call bar toggle
exec quickshell --path "$HOME/.config/hypr/utilities/quickshell/osd.qml"