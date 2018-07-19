#!/usr/bin/env bash
set -euo pipefail

# Shows the boot time and the userspace startup duration.
# Usage: boot-time [-h]
# Needs: Linux /proc, systemd-analyze (optional)

if [[ ! -r /proc/stat ]]; then
  printf 'Error: /proc/stat is missing. This tool needs Linux.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
boot-time - show the boot time and the startup duration.

Usage: boot-time

With systemd the tool shows the firmware, loader, kernel and userspace times,
plus the slowest units. Without systemd it shows the boot time and the uptime.
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h | --help) show_help; exit 0 ;;
    *) printf 'Error: unknown argument: %s\n' "$arg" >&2; show_help >&2; exit 1 ;;
  esac
done

if command -v systemd-analyze >/dev/null 2>&1; then
  systemd-analyze time
  printf '\n🐢 Slowest units:\n'
  systemd-analyze blame 2>/dev/null | head -n 5 || true
  exit 0
fi

btime=$(awk '/^btime/ {print $2}' /proc/stat)
up=$(awk '{printf "%d", $1}' /proc/uptime)
days=$((up / 86400))
hours=$(((up % 86400) / 3600))
mins=$(((up % 3600) / 60))

printf '🕒 Boot time: %s\n' "$(date -d "@$btime" '+%Y-%m-%d %H:%M:%S')"
printf '⏱️  Uptime: %s days, %s hours, %s minutes\n' "$days" "$hours" "$mins"
printf '   Userspace duration: not available without systemd-analyze.\n'
