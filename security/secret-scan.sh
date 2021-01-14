#!/usr/bin/env bash
# Scan files for likely secrets and show only their location.
# Usage: secret-scan.sh [-q] [PATH...] [-h]
# Note: Values are never printed. Check each hit by hand. Exits 1 on a hit.

set -euo pipefail

QUIET=0
FOUND=0
PATHS=()

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -q|--quiet) QUIET=1; shift ;;
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
  [ -e "$p" ] || die "no such path: $p"
done

scan() {
  local pattern=$1 label=$2 hits
  hits=$(grep -rInE --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=vendor \
    --exclude='*.min.js' --exclude='*.lock' -- "$pattern" "${PATHS[@]}" 2>/dev/null || true)
  [ -n "$hits" ] || return 0
  FOUND=$((FOUND + 1))
  [ "$QUIET" -eq 1 ] && return 0
  printf '🔍 %s\n' "$label"
  printf '%s\n' "$hits" | sed -E 's/^([^:]+:[0-9]+):.*/   \1: <redacted>/'
}

scan 'AKIA[0-9A-Z]{16}' 'AWS access key ID'
scan '-----BEGIN [A-Z ]*PRIVATE KEY-----' 'Private key block'
scan 'gh[pousr]_[A-Za-z0-9]{36,}' 'GitHub token'
scan 'xox[baprs]-[A-Za-z0-9-]{10,}' 'Slack token'
scan 'AIza[0-9A-Za-z_-]{35}' 'Google API key'
scan '(password|passwd|secret|api_key|apikey)[[:space:]]*[:=][[:space:]]*.[A-Za-z0-9_./+@-]{8,}' 'Possible hardcoded credential'

if [ "$FOUND" -gt 0 ]; then
  printf '\n⚠️  %s pattern(s) matched. Review the hits.\n' "$FOUND"
  exit 1
fi
printf '✅ No likely secrets found.\n'
