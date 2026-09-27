#!/usr/bin/env bash
# Usage: screenshot.sh full|region
# Saves to ~/Pictures/Screenshots and copies the image to the clipboard.
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "$1" in
	region)
		geom=$(slurp) || exit 0  # Esc cancels selection
		grim -g "$geom" "$file"
		;;
	*)
		grim "$file"
		;;
esac && wl-copy --type image/png < "$file"
