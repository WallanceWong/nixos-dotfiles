#!/bin/sh
# Lock the screen with whisper-shell's lock screen; fall back to hyprlock if
# the shell doesn't answer. `lock.sh login` waits a little for the shell
# (it may still be starting) and leaves a flag it picks up when it does.
PATH=/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH
flag="${XDG_RUNTIME_DIR:-/tmp}/whisper-locked"

tries=1
[ "$1" = login ] && { touch "$flag"; tries=40; }

i=0
while [ "$i" -lt "$tries" ]; do
    [ "$(qs ipc call whisper locked 2>/dev/null)" = true ] && exit 0
    qs ipc call whisper lock >/dev/null 2>&1 && exit 0
    i=$((i + 1))
    sleep 0.25
done

rm -f "$flag"   # don't let a late shell try to lock over hyprlock
pidof hyprlock >/dev/null || exec hyprlock
