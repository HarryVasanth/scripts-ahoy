#!/usr/bin/env bash
# Find world-writable files and setuid binaries.
# Usage: perm-audit.sh [-s] [PATH...] [-h]
# Note: Reports only. Some paths need sudo to read.

set -euo pipefail

SUID=0
PATHS=()

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -s | --suid)
      SUID=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        PATHS+=("$1")
        shift
      done
      ;;
    -*) die "unknown option $1" ;;
    *)
      PATHS+=("$1")
      shift
      ;;
  esac
done

if [ "${#PATHS[@]}" -eq 0 ]; then
  PATHS=(".")
fi
for p in "${PATHS[@]}"; do
  [ -e "$p" ] || die "no such path: $p"
done

report() {
  local label=$1 out count
  shift
  out=$(find "${PATHS[@]}" "$@" 2> /dev/null || true)
  if [ -z "$out" ]; then
    printf '✅ %s: none.\n' "$label"
    return 0
  fi
  count=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
  printf '⚠️  %s: %s found\n' "$label" "$count"
  printf '%s\n' "$out" | sed 's/^/   /'
}

report 'World-writable files' -type f -perm -0002
report 'World-writable folders without the sticky bit' -type d -perm -0002 ! -perm -1000

if [ "$SUID" -eq 1 ]; then
  report 'Setuid and setgid files' -type f \( -perm -4000 -o -perm -2000 \)
fi
