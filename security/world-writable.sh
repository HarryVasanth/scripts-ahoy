#!/usr/bin/env bash
# Find world-writable files and folders.
# Usage: world-writable.sh [PATH...]
# Needs: find
# Note: Run as root to see every file.

set -euo pipefail

PATHS=()

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --) shift; while [ "$#" -gt 0 ]; do PATHS+=("$1"); shift; done ;;
    -*) die "unknown option $1" ;;
    *) PATHS+=("$1"); shift ;;
  esac
done

if [ "${#PATHS[@]}" -eq 0 ]; then
  PATHS=(".")
fi

for p in "${PATHS[@]}"; do
  [ -d "$p" ] || die "no such folder: $p"
done

if [ "$(id -u)" -ne 0 ]; then
  printf 'ℹ️  Run as root to see every file. Some folders are hidden.\n\n'
fi

report() {
  local label=$1 out count
  shift
  out=$(find "${PATHS[@]}" -xdev "$@" 2>/dev/null || true)
  if [ -z "$out" ]; then
    printf '✅ %s: none.\n' "$label"
    return 0
  fi
  count=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
  printf '⚠️  %s: %s found\n' "$label" "$count"
  printf '%s\n' "$out" | sed 's/^/   /'
}

report 'World-writable files' -type f -perm -0002
printf '\n'
report 'World-writable folders without the sticky bit' -type d -perm -0002 ! -perm -1000

STICKY=$(find "${PATHS[@]}" -xdev -type d -perm -0002 -perm -1000 2>/dev/null | wc -l | tr -d ' ')
printf '\nℹ️  %s world-writable folder(s) have the sticky bit. These are common, for example /tmp.\n' "$STICKY"
