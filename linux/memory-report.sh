#!/usr/bin/env bash
set -euo pipefail

# Summarises RAM, swap and cache use from /proc/meminfo.
# Usage: memory-report [-h]
# Needs: Linux /proc

if [[ ! -r /proc/meminfo ]]; then
  printf 'Error: /proc/meminfo is missing. This tool needs Linux.\n' >&2
  exit 1
fi

show_help() {
  cat << 'EOF'
memory-report - show RAM, swap and cache use.

Usage: memory-report

The report shows total, used, free and available memory, the cache size and
the swap use. Sizes are in MB. Available memory is the best guide to free RAM.
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

value_of() {
  awk -v key="$1:" '$1 == key {print $2}' /proc/meminfo
}

total=$(value_of MemTotal)
free=$(value_of MemFree)
avail=$(value_of MemAvailable)
buffers=$(value_of Buffers)
cached=$(value_of Cached)
swap_total=$(value_of SwapTotal)
swap_free=$(value_of SwapFree)

# MemAvailable is missing before Linux 3.14.
if [[ -z "$avail" ]]; then
  avail=$((free + buffers + cached))
fi

used=$((total - avail))
cache=$((buffers + cached))
pct=$(awk -v u="$used" -v t="$total" 'BEGIN {printf "%.0f", t > 0 ? u * 100 / t : 0}')

printf '🧠 Memory\n'
printf '  Total:     %6s MB\n' "$((total / 1024))"
printf '  Used:      %6s MB (%s%%)\n' "$((used / 1024))" "$pct"
printf '  Free:      %6s MB\n' "$((free / 1024))"
printf '  Available: %6s MB\n' "$((avail / 1024))"
printf '  Cache:     %6s MB (buffers and page cache)\n' "$((cache / 1024))"

printf '\n💾 Swap\n'
if [[ $swap_total -eq 0 ]]; then
  printf '  No swap is configured.\n'
else
  swap_used=$((swap_total - swap_free))
  swap_pct=$(awk -v u="$swap_used" -v t="$swap_total" 'BEGIN {printf "%.0f", u * 100 / t}')
  printf '  Total: %6s MB\n' "$((swap_total / 1024))"
  printf '  Used:  %6s MB (%s%%)\n' "$((swap_used / 1024))" "$swap_pct"
  if [[ $swap_pct -ge 80 ]]; then
    printf '⚠️  Swap use is high. Check the top memory users with: ps aux --sort=-rss | head\n'
  fi
fi
