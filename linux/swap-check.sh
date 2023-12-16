#!/usr/bin/env bash
set -euo pipefail

# Reports swap usage and swappiness, and warns about risky values.
# Usage: swap-check [-w|--warn PCT] [-h]
# Needs: Linux /proc

if [[ ! -r /proc/meminfo ]]; then
  printf 'Error: /proc/meminfo is missing. This tool needs Linux.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
swap-check - show swap usage and the swappiness setting.

Usage: swap-check [--warn PCT]

  -w, --warn PCT   Warn when swap use is at this percentage or more.
                   Default: 80.
  -h, --help       Show this help.

The tool warns when no swap is configured and when swappiness is above 60.
EOF
}

warn_pct=80
while [[ $# -gt 0 ]]; do
  case "$1" in
    -w | --warn)
      [[ $# -ge 2 ]] || { printf 'Error: %s needs a value.\n' "$1" >&2; exit 1; }
      warn_pct=$2
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

if [[ ! $warn_pct =~ ^[0-9]+$ ]] || [[ $warn_pct -gt 100 ]]; then
  printf 'Error: the warning level must be 0 to 100.\n' >&2
  exit 1
fi

total=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo)
free_swap=$(awk '/^SwapFree:/ {print $2}' /proc/meminfo)
swappiness=$(cat /proc/sys/vm/swappiness 2>/dev/null || printf 'unknown')

total_mb=$((total / 1024))
used_mb=$(((total - free_swap) / 1024))

if [[ $total -eq 0 ]]; then
  printf '⚠️  No swap is configured.\n'
  printf '   Add a swap file or a swap partition if memory pressure is high.\n'
  exit 0
fi

pct=$(((total - free_swap) * 100 / total))
printf 'Swap total:  %s MB\n' "$total_mb"
printf 'Swap used:   %s MB (%s%%)\n' "$used_mb" "$pct"
printf 'Swappiness:  %s\n' "$swappiness"

printf '\nDevices:\n'
awk 'NR > 1 {printf "  %s  %s KB\n", $1, $3}' /proc/swaps

if [[ $pct -ge $warn_pct ]]; then
  printf '\n❌ Swap use is high. Check the top memory users with: ps aux --sort=-rss | head\n'
fi

if [[ $swappiness =~ ^[0-9]+$ ]] && [[ $swappiness -gt 60 ]]; then
  printf '⚠️  Swappiness is above 60. A value of 10 to 30 suits most desktops.\n'
fi
