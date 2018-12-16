#!/usr/bin/env bash
set -euo pipefail

# Compares the load average with the number of CPUs.
# Usage: load-average [-w PCT] [-h]
# Needs: Linux /proc

if [[ ! -r /proc/loadavg ]]; then
  printf 'Error: /proc/loadavg is missing. This tool needs Linux.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
load-average - compare the load average with the CPU count.

Usage: load-average [-w PCT]

  -w, --warn PCT   Warn when the 1-minute load per CPU reaches this
                   percentage. Default: 100.
  -h, --help       Show this help.

A load of 1.0 on a 4-CPU host is 25 percent. A value near 100 percent means
that work is waiting for a CPU.
EOF
}

warn=100
while [[ $# -gt 0 ]]; do
  case "$1" in
    -w | --warn)
      [[ $# -ge 2 ]] || { printf 'Error: %s needs a value.\n' "$1" >&2; exit 1; }
      warn=$2
      shift 2
      ;;
    -h | --help) show_help; exit 0 ;;
    *)
      printf 'Error: unknown argument: %s\n' "$1" >&2
      show_help >&2
      exit 1
      ;;
  esac
done

if [[ ! $warn =~ ^[0-9]+$ ]] || [[ $warn -eq 0 ]]; then
  printf 'Error: the warning level must be a positive number.\n' >&2
  exit 1
fi

read -r one five fifteen running lastpid < /proc/loadavg
cores=$(getconf _NPROCESSORS_ONLN 2>/dev/null || awk '/^processor/ {n++} END {print n + 0}' /proc/cpuinfo)
per_cpu=$(awk -v l="$one" -v c="$cores" 'BEGIN {printf "%.0f", c > 0 ? l * 100 / c : 0}')

printf '⚙️  CPUs: %s\n' "$cores"
printf '📈 Load average: %s  %s  %s  (1, 5, 15 min)\n' "$one" "$five" "$fifteen"
printf '   Running: %s   Last PID: %s\n' "$running" "$lastpid"
printf '   1-minute load per CPU: %s%%\n' "$per_cpu"

if [[ $per_cpu -ge $warn ]]; then
  printf '⚠️  The load is high. Find the busy processes with: ps aux --sort=-%%cpu | head\n'
else
  printf '✅ The load is within the warning level of %s%%.\n' "$warn"
fi
