#!/usr/bin/env bash
# Pick a colour anywhere on screen; the hex value is copied to the clipboard.
c=$(hyprpicker --autocopy --format=hex --no-fancy) || exit 0
[ -n "$c" ] && notify-send -a whisper -i color-select "Colour copied" "$c"
