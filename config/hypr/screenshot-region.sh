#!/bin/sh
set -eu

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"

geometry="$(slurp)" || exit 0
[ -n "$geometry" ] || exit 0

file="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"

grim -g "$geometry" "$file"

if command -v wl-copy >/dev/null 2>&1; then
    wl-copy --type image/png < "$file"
    notify-send "Screenshot copied" "$file"
else
    notify-send "Screenshot saved" "Install wl-clipboard to copy it: sudo pacman -S wl-clipboard"
fi
