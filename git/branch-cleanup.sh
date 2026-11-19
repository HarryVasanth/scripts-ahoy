#!/usr/bin/env bash
# Delete local branches that are already merged.
# Usage: branch-cleanup.sh [-b BASE] [--delete] [-h]
# Needs: git
# Note: It uses git branch -d only. It never force-deletes.

set -euo pipefail

BASE=
DO_DELETE=0

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -b)
      [ "$#" -ge 2 ] || die "-b needs a branch."
      BASE=$2
      shift 2
      ;;
    --delete)
      DO_DELETE=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "unknown option $1" ;;
  esac
done

git rev-parse --is-inside-work-tree > /dev/null 2>&1 || die "this is not a git repository."
git rev-parse --verify -q HEAD > /dev/null || die "no commits yet."

CURRENT=$(git symbolic-ref --short -q HEAD 2> /dev/null || true)
if [ -z "$BASE" ]; then
  if git show-ref --verify --quiet refs/heads/main; then
    BASE=main
  elif git show-ref --verify --quiet refs/heads/master; then
    BASE=master
  elif [ -n "$CURRENT" ]; then
    BASE=$CURRENT
  else
    die "cannot pick a base branch. Use -b BASE."
  fi
fi
git show-ref --verify --quiet "refs/heads/$BASE" || die "no local branch called $BASE"

LIST=$(git branch --merged "$BASE" --format='%(refname:short)' 2> /dev/null || true)
TARGETS=
while IFS= read -r b; do
  [ -n "$b" ] || continue
  git show-ref --verify --quiet "refs/heads/$b" || continue
  [ "$b" = "$BASE" ] && continue
  [ "$b" = "$CURRENT" ] && continue
  TARGETS+="$b"$'\n'
done <<< "$LIST"

if [ -z "$TARGETS" ]; then
  printf '✅ No merged branches to clean up.\n'
  exit 0
fi

printf '🧹 Merged into %s:\n' "$BASE"
printf '%s' "$TARGETS" | sed 's/^/   /'
printf '\n'

if [ "$DO_DELETE" -eq 0 ]; then
  printf 'Run with --delete to remove these branches.\n'
  exit 0
fi

printf 'Type yes to delete these branches: '
read -r answer
[ "$answer" = yes ] || {
  printf 'Cancelled.\n'
  exit 0
}

while IFS= read -r b; do
  [ -n "$b" ] || continue
  git branch -d "$b"
done <<< "$TARGETS"
printf '✅ Done.\n'
