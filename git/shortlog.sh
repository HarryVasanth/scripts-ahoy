#!/usr/bin/env bash
# Show a contributor summary by commit count.
# Usage: shortlog.sh [-n COUNT] [RANGE]
# Needs: git

set -euo pipefail

TOP=20
RANGE=HEAD

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n) [ "$#" -ge 2 ] || die "-n needs a number."; TOP=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option $1" ;;
    *)
      [ "$RANGE" = HEAD ] || die "give one range only."
      RANGE=$1
      shift
      ;;
  esac
done

case "$TOP" in
  ''|*[!0-9]*|0) die "-n needs a number above zero." ;;
esac

git rev-parse --git-dir >/dev/null 2>&1 || die "this is not a git repository."

TOTAL=$(git rev-list --count "$RANGE" 2>/dev/null) || die "bad range: $RANGE"
if [ "$TOTAL" -eq 0 ]; then
  printf 'ℹ️  No commits in %s.\n' "$RANGE"
  exit 0
fi

printf '🔎 Contributors in %s (%s commits)\n\n' "$RANGE" "$TOTAL"
git shortlog -sn --no-merges "$RANGE" |
  head -n "$TOP" |
  awk '{ name = $0; sub(/^[[:space:]]*[0-9]+[[:space:]]+/, "", name); printf "  %5d  %s\n", $1, name }'
