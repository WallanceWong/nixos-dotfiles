#!/usr/bin/env bash
# Usage: osd.sh volume up|down|mute | mic mute | brightness up|down
# Changes the value, then shows a progress popup through mako. The synchronous
# hint makes each popup replace the previous one instead of stacking.

notify() { # icon title percent
	notify-send -a osd -t 1400 -i "$1" \
		-h string:x-canonical-private-synchronous:osd \
		-h "int:value:$3" "$2" "$3%"
}

case "$1 $2" in
	"volume up")   wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
	"volume down") wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
	"volume mute") wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
	"mic mute")    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
	"brightness up")   brightnessctl -q set 5%+ ;;
	"brightness down") brightnessctl -q set 5%- ;;
esac

case "$1" in
	volume)
		v=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
		pct=$(awk '{printf "%d", $2 * 100 + 0.5}' <<< "$v")
		if [[ $v == *MUTED* ]]; then
			notify audio-volume-muted "Muted" "$pct"
		elif (( pct < 34 )); then notify audio-volume-low "Volume" "$pct"
		elif (( pct < 67 )); then notify audio-volume-medium "Volume" "$pct"
		else notify audio-volume-high "Volume" "$pct"
		fi
		;;
	mic)
		if [[ $(wpctl get-volume @DEFAULT_AUDIO_SOURCE@) == *MUTED* ]]; then
			notify-send -a osd -t 1400 -i microphone-sensitivity-muted \
				-h string:x-canonical-private-synchronous:osd "Microphone off"
		else
			notify-send -a osd -t 1400 -i audio-input-microphone \
				-h string:x-canonical-private-synchronous:osd "Microphone on"
		fi
		;;
	brightness)
		pct=$(brightnessctl -m | cut -d, -f4 | tr -d %)
		notify display-brightness "Brightness" "$pct"
		;;
esac
