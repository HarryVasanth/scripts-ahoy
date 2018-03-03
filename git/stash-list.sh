#!/usr/bin/env bash
# List stashes with age and changed files.
# Usage: stash-list.sh [-v] [-h]
# Needs: git

set -euo pipefail

VERBOSE=0

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -v|--verbose) VERBOSE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option $1" ;;
  esac
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "this is not a git repository."

LIST=$(git stash list --format='%gd%x09%cr%x09%gs' 2>/dev/null || true)
if [ -z "$LIST" ]; then
  printf 'ℹ️  No stashes.\n'
  exit 0
fi

if [ "$VERBOSE" -eq 0 ]; then
  printf '📦 Stashes\n\n'
  printf '%s\n' "$LIST" | awk -F'\t' '{ printf "%-10s %-20s %s\n", $1, $2, $3 }'
  exit 0
fi

while IFS=$'\t' read -r ref age msg; do
  printf '📦 %s  %s\n   %s\n' "$ref" "$age" "$msg"
  git stash show --stat "$ref" 2>/dev/null | sed 's/^/   /' || true
  printf '\n'
done <<< "$LIST"
