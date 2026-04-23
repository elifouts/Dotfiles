#!/bin/bash
WALLPAPER_DIR="$HOME/wallpapers/walls"
THUMBNAIL_DIR="$HOME/.cache/wallpaper_thumbnails"

mkdir -p "$THUMBNAIL_DIR"

generate_video_thumbnail() {
    local video_file="$1"
    local thumbnail_file="$THUMBNAIL_DIR/$(basename "$video_file" | sed 's/\.[^.]*$/.png/')"
    
    if [ ! -f "$thumbnail_file" ]; then
        ffmpeg -i "$video_file" -ss 00:00:01 -vframes 1 -vf "scale=200:112" "$thumbnail_file" -y 2>/dev/null
    fi
    
    echo "$thumbnail_file"
}

menu() {
    find "${WALLPAPER_DIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.mp4" -o -iname "*.mkv" \) | while read file; do
        if [[ "$file" =~ \.(mp4|mkv)$ ]]; then
            thumb=$(generate_video_thumbnail "$file")
            echo "img:$thumb"
        else
            echo "img:$file"
        fi
    done
}

main() {
    choice=$(menu | wofi -c /home/eren/.config/wofi/wallpaper -s /home/eren/.config/wofi/style-wallpaper.css --show dmenu --prompt "Select Wallpaper:" -n)
    selected_wallpaper=$(echo "$choice" | sed 's/^img://')
    
    # Find the actual file (not the thumbnail)
    actual_file=$(find "${WALLPAPER_DIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.mp4" -o -iname "*.mkv" \) | while read file; do
        if [[ "$file" =~ \.(mp4|mkv)$ ]]; then
            thumb=$(generate_video_thumbnail "$file")
            if [ "$thumb" == "$selected_wallpaper" ]; then
                echo "$file"
                break
            fi
        else
            if [ "$file" == "$selected_wallpaper" ]; then
                echo "$file"
                break
            fi
        fi
    done)
    
    # Kill any existing mpvpaper process first
    pkill mpvpaper 2>/dev/null
    sleep 0.5
    
    # Check if it's a video file
    if [[ "$actual_file" =~ \.(mp4|mkv)$ ]]; then
        # Play video as wallpaper using mpvpaper
        mpvpaper -o "no-audio --loop-file=inf" "*" "$actual_file" &
        
        # Extract first frame for wal color generation
        first_frame="$THUMBNAIL_DIR/$(basename "$actual_file" | sed 's/\.[^.]*$/.png/')"
        wal -i "$first_frame" -n --cols16
    else
        awww img "$actual_file" --transition-type any --transition-fps 60 --transition-duration .5
        wal -i "$actual_file" -n --cols16
    fi
    
    pkill swayosd-server
    swayosd-server &
    swaync-client --reload-css
    cat /home/eren/.cache/wal/colors-kitty.conf > /home/eren/.config/kitty/current-theme.conf
    pywalfox update
    color1=$(awk 'match($0, /color2=\47(.*)\47/,a) { print a[1] }' /home/eren/.cache/wal/colors.sh)
    color2=$(awk 'match($0, /color3=\47(.*)\47/,a) { print a[1] }' /home/eren/.cache/wal/colors.sh)
    cava_config="$HOME/.config/cava/config"
    sed -i "s/^gradient_color_1 = .*/gradient_color_1 = '$color1'/" $cava_config
    sed -i "s/^gradient_color_2 = .*/gradient_color_2 = '$color2'/" $cava_config
    pkill -USR2 cava 2>/dev/null
    source /home/eren/.cache/wal/colors.sh && cp -r $wallpaper /home/eren/wallpapers/pywallpaper.jpg 
}

main
