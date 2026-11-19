#!/usr/bin/env bash
set -euo pipefail

# Shows per-device read and write rates from /proc/diskstats.
# Usage: io-stats [-i SECONDS] [-n COUNT] [-h]
# Needs: Linux /proc, awk

interval=1
count=3

show_help() {
  cat << 'EOF'
io-stats - show per-device disk read and write rates.

Usage: io-stats [-i SECONDS] [-n COUNT]

  -i, --interval SECONDS   Time between samples. Default: 1.
  -n, --count COUNT        Number of samples. Default: 3.
  -h, --help               Show this help.

Rates are in KB/s. The tool reads /proc/diskstats, or iostat with sysstat.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i | --interval)
      [[ $# -ge 2 ]] || {
        printf 'Error: %s needs a value.\n' "$1" >&2
        exit 1
      }
      interval=$2
      shift 2
      ;;
    -n | --count)
      [[ $# -ge 2 ]] || {
        printf 'Error: %s needs a value.\n' "$1" >&2
        exit 1
      }
      count=$2
      shift 2
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      printf 'Error: unknown argument: %s\n' "$1" >&2
      show_help >&2
      exit 1
      ;;
  esac
done

if [[ ! $interval =~ ^[0-9]+$ ]] || [[ $interval -eq 0 ]] \
  || [[ ! $count =~ ^[0-9]+$ ]] || [[ $count -eq 0 ]]; then
  printf 'Error: the interval and the count must be positive numbers.\n' >&2
  exit 1
fi

if [[ ! -r /proc/diskstats ]]; then
  if command -v iostat > /dev/null 2>&1; then
    iostat -d -k "$interval" "$count"
    exit 0
  fi
  printf 'Error: /proc/diskstats is missing and iostat is not installed.\n' >&2
  printf 'Install sysstat: sudo apt install sysstat\n' >&2
  exit 1
fi
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT
snapshot() {
  awk '$3 ~ /^(sd|hd|vd|xvd|nvme|md|dm-)/ {print $3, $4, $6, $8, $10}' /proc/diskstats
}

for ((i = 1; i <= count; i++)); do
  snapshot > "$tmp/first"
  sleep "$interval"
  snapshot > "$tmp/second"
  printf '\n📊 Sample %s over %s s (KB/s)\n' "$i" "$interval"
  printf '  %-12s %10s %10s\n' 'DEVICE' 'READ' 'WRITE'
  # Fields: name, reads, sectors read, writes, sectors written.
  awk -v iv="$interval" '
    FILENAME == ARGV[1] {sr[$1] = $3; sw[$1] = $5; next}
    {
      rd = ($3 - sr[$1]) * 512 / 1024 / iv
      wr = ($5 - sw[$1]) * 512 / 1024 / iv
      printf "  %-12s %10.0f %10.0f\n", $1, rd, wr
    }
  ' "$tmp/first" "$tmp/second"
done
