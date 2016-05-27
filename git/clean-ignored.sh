#!/usr/bin/env bash
# List or remove ignored files. It is a dry run by default.
# Usage: clean-ignored.sh [-f] [-h]
# Needs: git

set -euo pipefail

FORCE=0

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -f|--force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option $1" ;;
  esac
done

git rev-parse --git-dir >/dev/null 2>&1 || die "this is not a git repository."

if [ "$FORCE" -eq 0 ]; then
  LIST=$(git clean -ndX 2>/dev/null || true)
  printf '🔎 Ignored files and folders (dry run)\n\n'
  if [ -z "$LIST" ]; then
    printf '✅ Nothing to clean.\n'
    exit 0
  fi
  printf '%s\n' "$LIST" | sed 's/^/   /'
  COUNT=$(printf '%s\n' "$LIST" | wc -l | tr -d ' ')
  printf '\n  %s item(s). Nothing was removed. Use -f to remove them.\n' "$COUNT"
  exit 0
fi

printf '⚠️  Removing ignored files. They are not tracked and cannot be restored.\n\n' >&2
git clean -fdX
printf '\n✅ Ignored files removed.\n'
