#!/usr/bin/env bash
# Show a compact graph log with basic filters.
# Usage: log-graph.sh [-n COUNT] [-a AUTHOR] [-g PATTERN] [-b BRANCH] [-h]
# Needs: git

set -euo pipefail

COUNT=20
AUTHOR=
PATTERN=
BRANCH=HEAD

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n)
      [ "$#" -ge 2 ] || die "-n needs a number."
      COUNT=$2
      shift 2
      ;;
    -a)
      [ "$#" -ge 2 ] || die "-a needs a name."
      AUTHOR=$2
      shift 2
      ;;
    -g)
      [ "$#" -ge 2 ] || die "-g needs a pattern."
      PATTERN=$2
      shift 2
      ;;
    -b)
      [ "$#" -ge 2 ] || die "-b needs a branch."
      BRANCH=$2
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "unknown option $1" ;;
  esac
done

case "$COUNT" in
  '' | *[!0-9]* | 0) die "-n needs a number above zero." ;;
esac

git rev-parse --git-dir > /dev/null 2>&1 || die "this is not a git repository."
git rev-parse --verify -q "$BRANCH" > /dev/null || die "no such branch or commit: $BRANCH"

ARGS=(--graph --oneline --decorate -n "$COUNT")
if [ -n "$AUTHOR" ]; then
  ARGS+=("--author=$AUTHOR")
fi
if [ -n "$PATTERN" ]; then
  ARGS+=("--grep=$PATTERN")
fi

printf '🔎 Graph log for %s\n\n' "$BRANCH"
git log "${ARGS[@]}" "$BRANCH"
