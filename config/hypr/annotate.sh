#!/usr/bin/env bash
# Screenshot a region, then draw on it in satty before saving / copying.
# Enter copies, Ctrl+S saves to ~/Pictures/Screenshots.
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
geom=$(slurp -b '#071a2866' -c '#f0e3a8' -w 2) || exit 0   # Esc cancels
grim -g "$geom" - | satty --filename - \
	--output-filename "$dir/drawn-$(date +%Y-%m-%d_%H-%M-%S).png" \
	--copy-command wl-copy --early-exit --initial-tool brush --font-family Nunito
