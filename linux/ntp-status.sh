#!/usr/bin/env bash
set -euo pipefail

# Shows the time sync state with timedatectl, chronyc or ntpq.
# Usage: ntp-status [-h]
# Needs: timedatectl, chronyc or ntpq

if [[ $(uname -s) != Linux ]]; then
  printf 'Error: this tool needs Linux.\n' >&2
  exit 1
fi

show_help() {
  cat << 'EOF'
ntp-status - show the time sync state of the host.

Usage: ntp-status

The tool uses every tool that it finds. timedatectl shows the systemd view.
chronyc shows the chrony view. ntpq shows the peers of a classic ntpd.
A host is in sync when the output says "synchronized: yes" or the offset is
small.
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

found=0
if command -v timedatectl > /dev/null 2>&1; then
  printf '🕒 timedatectl\n'
  timedatectl status 2> /dev/null \
    | grep -Ei 'Local time|Universal time|Time zone|synchronized|NTP service' \
    | sed 's/^ */  /' || true
  found=1
fi

if command -v chronyc > /dev/null 2>&1; then
  printf '\n🕒 chronyc\n'
  chronyc tracking 2> /dev/null \
    | grep -E 'Reference ID|Stratum|System time|Last offset|Leap status' \
    | sed 's/^ */  /' || true
  found=1
fi

if command -v ntpq > /dev/null 2>&1; then
  printf '\n🕒 ntpq\n'
  ntpq -p 2> /dev/null || true
  found=1
fi

if [[ $found -eq 0 ]]; then
  printf 'Error: no time sync tool found.\n' >&2
  printf 'Install one: sudo apt install systemd-timesyncd  (or chrony, or ntp)\n' >&2
  exit 1
fi
