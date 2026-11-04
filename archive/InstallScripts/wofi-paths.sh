#!/bin/bash

fix_wofi_paths() {
    local dir="${1:-$HOME/.config/wofi}" file replacement

    [[ -d "$dir" ]] || return 0
    dir="$(readlink -f "$dir")"

    replacement="${HOME//\\/\\\\}"
    replacement="${replacement//&/\\&}"
    replacement="${replacement//|/\\|}"

    while IFS= read -r -d '' file; do
        sed -i -E \
            "s|/home/[^/]+/\\.cache/wal/colors-waybar\\.css|${replacement}/.cache/wal/colors-waybar.css|g" \
            "$file"
    done < <(find "$dir" -maxdepth 1 -type f -name '*.css' -print0)
}

fix_wofi_paths