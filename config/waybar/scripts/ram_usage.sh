#!/usr/bin/env bash

set -euo pipefail

STATE_FILE="/tmp/waybar_resource_mode_${USER:-ze}"

read_mode() {
  if [[ -f "$STATE_FILE" ]]; then
    cat "$STATE_FILE"
    return
  fi
  echo "ram"
}

next_mode() {
  local current
  current="$(read_mode)"

  case "$current" in
    ram) echo "cpu" > "$STATE_FILE" ;;
    cpu) echo "gpu" > "$STATE_FILE" ;;
    *) echo "ram" > "$STATE_FILE" ;;
  esac
}

ram_usage() {
  local total available used percent
  total="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
  available="$(awk '/MemAvailable/ {print $2}' /proc/meminfo)"
  used=$((total - available))
  percent=$((used * 100 / total))
  echo "RAM: ${percent}%"
}

cpu_usage() {
  local -a a b
  local idle1 total1 idle2 total2 d_idle d_total usage

  read -r -a a < /proc/stat
  idle1=$((a[4] + a[5]))
  total1=0
  for v in "${a[@]:1:8}"; do
    total1=$((total1 + v))
  done

  sleep 0.2
  read -r -a b < /proc/stat
  idle2=$((b[4] + b[5]))
  total2=0
  for v in "${b[@]:1:8}"; do
    total2=$((total2 + v))
  done

  d_idle=$((idle2 - idle1))
  d_total=$((total2 - total1))
  if ((d_total <= 0)); then
    echo "CPU: 0%"
    return
  fi

  usage=$(((100 * (d_total - d_idle)) / d_total))
  echo "CPU: ${usage}%"
}

gpu_usage() {
  local util

  if command -v nvidia-smi >/dev/null 2>&1; then
    util="$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d '[:space:]' || true)"
    if [[ "$util" =~ ^[0-9]+$ ]]; then
      echo "GPU: ${util}%"
      return
    fi
  fi

  if [[ -r /sys/class/drm/card0/device/gpu_busy_percent ]]; then
    util="$(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || true)"
    if [[ "$util" =~ ^[0-9]+$ ]]; then
      echo "GPU: ${util}%"
      return
    fi
  fi

  echo "GPU: n/a"
}

if [[ "${1:-}" == "next" ]]; then
  next_mode
  exit 0
fi

case "$(read_mode)" in
  ram) ram_usage ;;
  cpu) cpu_usage ;;
  gpu) gpu_usage ;;
  *) ram_usage ;;
esac
