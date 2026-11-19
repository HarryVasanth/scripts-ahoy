#!/usr/bin/env bash
set -euo pipefail

# Shows failed systemd units and the last log lines for each one.
# Usage: systemd-status [-a|--all] [-h|--help]
# Needs: systemctl, journalctl (systemd)

show_help() {
  cat << 'EOF'
systemd-status - show failed systemd units.

Usage: systemd-status [--all]

  -a, --all   List every unit, not only the failed ones.
  -h, --help  Show this help.

The exit status is 1 when a unit has failed.
EOF
}

show_all=0
for arg in "$@"; do
  case "$arg" in
    -a | --all) show_all=1 ;;
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

if ! command -v systemctl > /dev/null 2>&1; then
  printf 'Error: systemctl is missing. This tool needs systemd.\n' >&2
  exit 1
fi

if [[ $show_all -eq 1 ]]; then
  systemctl list-units --type=service --all --no-pager
  exit 0
fi

failed=$(systemctl --failed --no-legend --no-pager)
if [[ -z "$failed" ]]; then
  printf '✅ No failed units.\n'
  exit 0
fi

printf '❌ Failed units:\n\n%s\n' "$failed"

while read -r unit _; do
  [[ -z "$unit" ]] && continue
  printf '\n--- %s ---\n' "$unit"
  journalctl -u "$unit" -n 5 --no-pager -o cat 2> /dev/null || true
done <<< "$failed"

exit 1
