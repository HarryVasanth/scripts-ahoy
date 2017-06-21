#!/usr/bin/env bash
# Build a grouped changelog from commit messages.
# Usage: changelog.sh [RANGE] [-h]
# Needs: git
# Note: It groups conventional commit types. Other subjects go under Other.

set -euo pipefail

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

RANGE=
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option $arg" ;;
    *) [ -z "$RANGE" ] || die "give one range at most."; RANGE=$arg ;;
  esac
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "this is not a git repository."
git rev-parse --verify -q HEAD >/dev/null || die "no commits yet."

SINCE=
if [ -z "$RANGE" ]; then
  LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || true)
  if [ -n "$LAST_TAG" ]; then
    RANGE="$LAST_TAG..HEAD"
    SINCE=" since $LAST_TAG"
  fi
fi

if [ -n "$RANGE" ]; then
  LOG=$(git log --no-merges --format='%h %s' "$RANGE" 2>/dev/null || true)
else
  LOG=$(git log --no-merges --format='%h %s' -n 200 2>/dev/null || true)
fi
if [ -z "$LOG" ]; then
  printf 'ℹ️  No commits in this range.\n'
  exit 0
fi

heading() {
  case "$1" in
    feat) printf 'Features' ;; fix) printf 'Fixes' ;; docs) printf 'Documentation' ;;
    perf) printf 'Performance' ;; refactor) printf 'Refactoring' ;; test) printf 'Tests' ;;
    build) printf 'Build' ;; ci) printf 'CI' ;; chore) printf 'Chores' ;;
  esac
}

printf '## Changes%s\n' "$SINCE"
for t in feat fix docs perf refactor test build ci chore; do
  MATCH=$(printf '%s\n' "$LOG" | grep -E "^[0-9a-f]+ ${t}(\(|!|:)" || true)
  [ -n "$MATCH" ] || continue
  printf '\n### %s\n' "$(heading "$t")"
  printf '%s\n' "$MATCH" | sed 's/^/- /'
done

OTHER=$(printf '%s\n' "$LOG" |
  grep -vE "^[0-9a-f]+ (feat|fix|docs|perf|refactor|test|build|ci|chore)(\(|!|:)" || true)
if [ -n "$OTHER" ]; then
  printf '\n### Other\n'
  printf '%s\n' "$OTHER" | sed 's/^/- /'
fi
