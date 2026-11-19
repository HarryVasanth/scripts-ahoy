#!/usr/bin/env bash
# Undo the last commit and keep its changes.
# Usage: undo-commit.sh [--unstage] [-y] [-h]
# Needs: git
# Note: It rewrites local history. It asks before it touches a pushed commit.

set -euo pipefail

UNSTAGE=0
ASSUME_YES=0

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --unstage)
      UNSTAGE=1
      shift
      ;;
    -y | --yes)
      ASSUME_YES=1
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

printf '🕐 Last commit: %s\n' "$(git log -1 --format='%h %s')"
REMOTE_REF=$(git branch -r --contains HEAD 2> /dev/null | head -n 1 || true)
if [ -n "$REMOTE_REF" ]; then
  printf '⚠️  This commit is on a remote branch (%s).\n' "$REMOTE_REF"
  if [ "$ASSUME_YES" -eq 0 ]; then
    printf 'Continue? [y/N] '
    read -r reply
    case "$reply" in
      y | Y | yes) ;;
      *)
        printf 'Cancelled.\n'
        exit 0
        ;;
    esac
  fi
fi

if git rev-parse --verify -q HEAD~1 > /dev/null; then
  if [ "$UNSTAGE" -eq 1 ]; then
    git reset HEAD~1
  else
    git reset --soft HEAD~1
  fi
else
  git update-ref -d HEAD
  printf 'ℹ️  Removed the root commit. Files stay staged.\n'
fi

printf '\n✅ The commit is undone. The changes are kept.\n'
git status --short 2> /dev/null | head -n 10 || true
