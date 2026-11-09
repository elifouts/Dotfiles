HYPR="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
UTIL="$HYPR/utilities"
STYLE="$HYPR/${HYPR_STYLE:-$(cut -d/ -f1 "$HYPR/state/profile" 2>/dev/null || echo Modern)}"
QS="$HYPR/quickshell"
