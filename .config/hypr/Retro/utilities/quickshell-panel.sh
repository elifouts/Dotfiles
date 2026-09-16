#!/bin/sh
set -eu
QS_PANEL_MODE="${1:-audio}" exec quickshell --path "$HOME/.config/hypr/utilities/quickshell/panel.qml" --no-duplicate