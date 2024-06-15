#!/usr/bin/env bash
set -euo pipefail

# Show the current Wi-Fi network name and signal strength.
# Usage: wifi-info.sh
# Needs: system_profiler (macOS) or iw/nmcli (Linux)

usage() {
  printf 'Usage: %s\n  Shows the SSID, signal, and noise for the active Wi-Fi link.\n' "${0##*/}"
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then usage; exit 0; fi

os=$(uname -s)
if [[ $os == Darwin ]]; then
  command -v system_profiler >/dev/null 2>&1 \
    || { printf 'Error: system_profiler is not available.\n' >&2; exit 1; }
  info=$(system_profiler SPAirPortDataType 2>/dev/null) || info=""
  ssid=$(printf '%s\n' "$info" | awk '/Current Network Information:/ { getline; sub(/^[ \t]+/, ""); sub(/:$/, ""); print; exit }')
  signal=$(printf '%s\n' "$info" | awk -F': ' '/Signal \/ Noise/ { print $2; exit }')
  noise=""
  if [[ -n $signal ]]; then
    noise=${signal#*/ }
    signal=${signal%% / *}
  fi
elif [[ $os == Linux ]]; then
  ssid="" signal=""
  if command -v iwgetid >/dev/null 2>&1; then
    ssid=$(iwgetid -r 2>/dev/null) || ssid=""
    iface=$(iwgetid 2>/dev/null | awk '{ print $1 }') || iface=""
    if [[ -n $iface ]] && command -v iw >/dev/null 2>&1; then
      signal=$(iw dev "$iface" link 2>/dev/null | sed -n 's/.*signal: *\(-*[0-9]* dBm\).*/\1/p') || signal=""
    fi
  fi
  if [[ -z $ssid ]] && command -v nmcli >/dev/null 2>&1; then
    ssid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1 == "yes" { print $2; exit }') || ssid=""
    signal=$(nmcli -t -f ACTIVE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1 == "yes" { print $2; exit }') || signal=""
    [[ -n $signal ]] && signal="$signal%"
  fi
else
  printf 'Error: this script supports macOS and Linux only.\n' >&2
  exit 1
fi

if [[ -z ${ssid:-} ]]; then
  printf '❌ No active Wi-Fi network. Check that Wi-Fi is on.\n' >&2
  exit 1
fi

printf '📶 Wi-Fi\n   SSID:    %s\n' "$ssid"
if [[ -n ${signal:-} ]]; then
  printf '   Signal:  %s\n' "$signal"
else
  printf '   Signal:  not reported\n'
fi
[[ -z ${noise:-} ]] || printf '   Noise:   %s\n' "$noise"
