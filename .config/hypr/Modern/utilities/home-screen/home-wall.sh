#!/bin/bash
set -uo pipefail

dir="$HOME/.cache/hypr-home"
mkdir -p "$dir"
used=()

cache() {
    local src="$1" key
    [ -f "$src" ] || return 1
    key="$(printf '%s %s' "$src" "$(stat -c %Y "$src")" | sha1sum | cut -d' ' -f1)"
    result="$dir/$key.jpg"
    if [ ! -s "$result" ]; then
        vipsthumbnail "$src" -s 2560x2560 -o "$result[Q=88]" >/dev/null 2>&1 || { result="$src"; return 0; }
    fi
    used+=("$result")
}

if wal_src="$(< "$HOME/.cache/wal/wal")" && cache "$wal_src"; then
    printf '*\t%s\n' "$result"
fi

re='^: ?([^:]+):.*image: (.+)$'
while IFS= read -r line; do
    if [[ "$line" =~ $re ]]; then
        name="${BASH_REMATCH[1]}"
        cache "${BASH_REMATCH[2]}" && printf '%s\t%s\n' "$name" "$result"
    fi
done < <(awww query 2>/dev/null)

[ "${#used[@]}" -gt 0 ] && find "$dir" -name '*.jpg' | grep -vxF -f <(printf '%s\n' "${used[@]}") | xargs -r rm -f
