#!/usr/bin/env bash
set -euo pipefail

# Shows the Time Machine state, destinations and recent backups.
# Usage: timemachine-status [-h]
# Needs: tmutil

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

if ! command -v tmutil >/dev/null 2>&1; then
  printf 'Error: tmutil is missing. This tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
timemachine-status - report the Time Machine state.

Usage: timemachine-status

Shows whether a backup runs, the backup destinations and the last three
backups. Run "tmutil startbackup" to start one by hand.
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h | --help) show_help; exit 0 ;;
    *)
      printf 'Error: unknown argument: %s\n' "$arg" >&2
      show_help >&2
      exit 1
      ;;
  esac
done

printf '== State ==\n'
status=$(tmutil status 2>/dev/null || true)
running=$(printf '%s\n' "$status" | awk -F'= ' '/Running/ {gsub(/;/, "", $2); print $2; exit}')
case "$running" in
  1)
    printf '⏳ A backup is running.\n'
    percent=$(printf '%s\n' "$status" | awk -F'= ' '/Percent/ {gsub(/;/, "", $2); print $2; exit}')
    if [[ -n "$percent" ]]; then
      printf 'Progress: %s%%\n' "$(awk -v p="$percent" 'BEGIN {printf "%.0f", p * 100}')"
    fi
    ;;
  0) printf '💤 No backup is running.\n' ;;
  *) printf 'Unknown.\n' ;;
esac

printf '\n== Destinations ==\n'
destinations=$(tmutil destinationinfo 2>&1 || true)
printf '%s\n' "$destinations"

printf '\n== Latest backup ==\n'
latest=$(tmutil latestbackup 2>/dev/null || true)
printf '%s\n' "${latest:-None.}"

printf '\n== Recent backups ==\n'
recent=$(tmutil listbackups 2>/dev/null | grep -v '^Command exited' | tail -n 3 || true)
printf '%s\n' "${recent:-None.}"
