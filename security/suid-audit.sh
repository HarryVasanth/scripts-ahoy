#!/usr/bin/env bash
# List setuid and setgid files.
# Usage: suid-audit.sh [PATH...]
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
  PATHS=("/")
fi

for p in "${PATHS[@]}"; do
  [ -d "$p" ] || die "no such folder: $p"
done

if [ "$(id -u)" -ne 0 ]; then
  printf 'ℹ️  Run as root to see every file. Some folders are hidden.\n\n'
fi

scan() {
  local label=$1 bits=$2 out count
  out=$(find "${PATHS[@]}" -xdev -type f -perm -"$bits" 2>/dev/null || true)
  if [ -z "$out" ]; then
    printf '✅ %s: none.\n' "$label"
    return 0
  fi
  count=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
  printf '⚠️  %s: %s found\n' "$label" "$count"
  printf '%s\n' "$out" | sed 's/^/   /'
}

scan 'Setuid files' 4000
printf '\n'
scan 'Setgid files' 2000
printf '\n🔎 Common setuid files are su, sudo, passwd, ping and mount. Check each extra file.\n'
