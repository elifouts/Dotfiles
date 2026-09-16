#!/bin/sh
set -eu
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/hypr"
cache="$cache_dir/launcher-apps-v2.tsv"
mkdir -p "$cache_dir"

resolve_icon() {
	icon="$1"
	case "$icon" in
		/*) printf '%s' "$icon"; return ;;
	esac
	for theme in "$HOME/.local/share/icons"/* /usr/share/icons/*; do
		[ -d "$theme" ] || continue
		resolved=$(find "$theme" -type f \( -name "$icon.svg" -o -name "$icon.png" -o -name "$icon.xpm" \) 2>/dev/null | sort | head -1)
		if [ -n "$resolved" ]; then
			printf '%s' "$resolved"
			return
		fi
	done
	printf '%s' "$icon"
}

if [ ! -s "$cache" ]; then
	find "$HOME/.local/share/applications" /usr/share/applications -type f -name '*.desktop' 2>/dev/null | sort -u | while read -r file; do
		if grep -qE '^(NoDisplay|Hidden)=true' "$file"; then
			continue
		fi
		name=$(grep -m1 '^Name=' "$file" | cut -d= -f2-)
		exec_line=$(grep -m1 '^Exec=' "$file" | cut -d= -f2- | sed 's/ %[fFuUdDnNickvm]//g')
		icon=$(grep -m1 '^Icon=' "$file" | cut -d= -f2-)
		[ -n "$icon" ] && icon=$(resolve_icon "$icon")
		[ -n "$name" ] && [ -n "$exec_line" ] && printf '%s\t%s\t%s\n' "$name" "$exec_line" "$icon"
	done > "$cache"
fi

exec quickshell --path "$HOME/.config/hypr/utilities/quickshell/launcher.qml" --no-duplicate
