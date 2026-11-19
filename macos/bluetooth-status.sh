#!/usr/bin/env bash
set -euo pipefail

# Shows the Bluetooth power state and the paired devices.
# Usage: bluetooth-status [-h]
# Needs: system_profiler, defaults

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat << 'EOF'
bluetooth-status - show Bluetooth power and devices.

Usage: bluetooth-status

The tool reads the controller power state and the device list from
system_profiler. A connected device shows its name under the device list.
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      printf 'Error: unknown argument: %s\n' "$arg" >&2
      show_help >&2
      exit 1
      ;;
  esac
done

power=$(defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState 2> /dev/null || printf '')

raw=$(system_profiler SPBluetoothDataType 2> /dev/null || true)
if [[ -z "$raw" ]]; then
  printf 'Error: no Bluetooth data. This Mac may have no Bluetooth.\n' >&2
  exit 1
fi

if [[ -z "$power" ]]; then
  case "$raw" in
    *'State: On'*) power=1 ;;
    *'State: Off'*) power=0 ;;
  esac
fi

if [[ "$power" == 1 ]]; then
  printf '🔵 Bluetooth is on.\n'
elif [[ "$power" == 0 ]]; then
  printf '⚫ Bluetooth is off.\n'
fi

printf '\n📶 Devices\n'
printf '%s\n' "$raw" | awk '
  /^ {6}[^ ].*:$/ {sub(/^ +/, ""); printf "\n  %s\n", $0; next}
  /^ {10}[^ ].*:$/ {sub(/^ +/, ""); printf "    %s\n", $0; next}
  /State:|Connected:/ {
    sub(/^[[:space:]]+/, "")
    printf "    %s\n", $0
  }
  /Address:/ {
    sub(/^[[:space:]]+/, "")
    printf "      %s\n", $0
  }
'
