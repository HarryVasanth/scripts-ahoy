#!/usr/bin/env bash
set -euo pipefail

# Reports Mac battery charge, cycle count and capacity health.
# Usage: battery-health [-h]
# Needs: pmset, ioreg

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
battery-health - report the state of the Mac battery.

Usage: battery-health

Shows the charge level, the cycle count, the design capacity, the current
maximum capacity and the health percentage. A health value below 80 percent
means the battery is worn.
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h | --help) show_help; exit 0 ;;
    *) printf 'Error: unknown argument: %s\n' "$arg" >&2; show_help >&2; exit 1 ;;
  esac
done

raw=$(ioreg -rn AppleSmartBattery 2>/dev/null || true)
if [[ -z "$raw" ]]; then
  printf 'Error: no battery found. This Mac has no internal battery.\n' >&2
  exit 1
fi

value_of() {
  printf '%s\n' "$raw" | grep -o "\"$1\"[ ]*=[ ]*[0-9]*" | head -n 1 |
    sed 's/[^0-9]//g' || true
}

design=$(value_of DesignCapacity)
maximum=$(value_of AppleRawMaxCapacity)
if [[ -z "$maximum" ]]; then
  maximum=$(value_of MaxCapacity)
fi
cycles=$(value_of CycleCount)

charge=$(pmset -g batt | awk 'NR == 2 {gsub(/;/, "", $3); print $3}')
printf 'Charge: %s\n' "${charge:-unknown}"

if [[ -n "$design" && -n "$maximum" && "$design" -gt 0 ]]; then
  health=$(awk -v max="$maximum" -v des="$design" 'BEGIN {printf "%.0f", max * 100 / des}')
  printf 'Design capacity:  %s mAh\n' "$design"
  printf 'Maximum capacity: %s mAh\n' "$maximum"
  printf 'Health: %s%%\n' "$health"
  if [[ "$health" -lt 80 ]]; then
    printf '⚠️  The battery is worn. Book a service if the runtime is short.\n'
  else
    printf '✅ The battery health is good.\n'
  fi
else
  printf 'Health: unknown. macOS did not report the capacity.\n'
fi

if [[ -n "$cycles" ]]; then
  printf 'Cycle count: %s\n' "$cycles"
  if [[ "$cycles" -gt 1000 ]]; then
    printf '⚠️  The cycle count is above the usual 1000 limit.\n'
  fi
fi
