#!/usr/bin/env bash
# Summarise the state of submodules.
# Usage: submodule-status.sh [-h]
# Needs: git

set -euo pipefail

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    *) die "unknown option $1" ;;
  esac
done

git rev-parse --git-dir >/dev/null 2>&1 || die "this is not a git repository."

if [ ! -f .gitmodules ]; then
  printf '✅ No submodules. There is no .gitmodules file.\n'
  exit 0
fi

STATUS=$(git submodule status 2>/dev/null || true)
if [ -z "$STATUS" ]; then
  printf '⚠️  .gitmodules exists, but git lists no submodules.\n'
  exit 0
fi

printf '🔎 Submodule state\n\n'
printf '%s\n' "$STATUS" | awk '
  {
    state = "in sync"
    if ($1 ~ /^-/) state = "not initialised"
    else if ($1 ~ /^\+/) state = "other commit"
    else if ($1 ~ /^U/) state = "conflict"
    printf "   %-16s %s\n", state, $2
  }
'

TOTAL=$(printf '%s\n' "$STATUS" | wc -l | tr -d ' ')
MISSING=$(printf '%s\n' "$STATUS" | grep -c '^-' || true)
CHANGED=$(printf '%s\n' "$STATUS" | grep -cE '^[+U]' || true)

printf '\n  %-16s %s\n' 'Submodules' "$TOTAL"
printf '  %-16s %s\n' 'Not initialised' "${MISSING:-0}"
printf '  %-16s %s\n' 'Other commit' "${CHANGED:-0}"

if [ "${MISSING:-0}" -gt 0 ]; then
  printf '\nℹ️  Run: git submodule update --init --recursive\n'
fi
