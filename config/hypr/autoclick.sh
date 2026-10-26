#!/usr/bin/env bash
# Auto clicker: press once to start left-clicking where the mouse is, again to stop.
# Speed: clicks per second as the first argument (default 20), e.g. autoclick.sh 50
export YDOTOOL_SOCKET=${YDOTOOL_SOCKET:-/run/ydotoold/socket}
# just added to the ydotool group but not logged in again yet: borrow the group
if ! id -nG | grep -qw ydotool; then exec sg ydotool -c "$(printf '%q ' "$0" "$@")"; fi
pidfile=${XDG_RUNTIME_DIR:-/tmp}/autoclick.pid

if [ -f "$pidfile" ] && kill "$(cat "$pidfile")" 2>/dev/null; then
  rm -f "$pidfile"
  notify-send -a whisper -i input-mouse "Auto clicker" "Stopped"
  exit 0
fi

cps=${1:-20}
delay=$(awk "BEGIN { print 1 / $cps }")
notify-send -a whisper -i input-mouse "Auto clicker" "Clicking $cps times a second — Super+Alt+C to stop"
(
  while ydotool click 0xC0 >/dev/null 2>&1; do sleep "$delay"; done
  rm -f "$pidfile"
  notify-send -a whisper -i dialog-error "Auto clicker" "Stopped: ydotool isn't working (log out and back in once after installing)"
) &
echo $! > "$pidfile"
