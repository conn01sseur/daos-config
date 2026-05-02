#!/usr/bin/env bash

set -euo pipefail

action="${1:-}"

if command -v wpctl >/dev/null 2>&1; then
  case "$action" in
    toggle) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    up) wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+ ;;
    down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    *) exit 1 ;;
  esac
  exit 0
fi

if command -v pactl >/dev/null 2>&1; then
  case "$action" in
    toggle) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
    up) pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
    down) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
    *) exit 1 ;;
  esac
  exit 0
fi

exit 1
