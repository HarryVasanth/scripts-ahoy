#!/usr/bin/env bash
# Show commits over time as a bar chart.
# Usage: commit-activity.sh [-n COUNT] [-a AUTHOR] [-d] [-h]
# Needs: git
# Note: Without -d it groups by month. With -d it groups by day.

set -euo pipefail

COUNT=12
AUTHOR=
DAILY=0

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
    -d | --daily)
      DAILY=1
      shift
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

git rev-parse --is-inside-work-tree > /dev/null 2>&1 || die "this is not a git repository."

if [ "$DAILY" -eq 1 ]; then
  SINCE="$COUNT days ago"
  FMT='%Y-%m-%d'
  UNIT=day
else
  SINCE="$COUNT months ago"
  FMT='%Y-%m'
  UNIT=month
fi

LOG=(git log --since="$SINCE" --date="format:$FMT" --pretty=format:%ad)
if [ -n "$AUTHOR" ]; then
  LOG+=(--author="$AUTHOR")
fi

OUT=$("${LOG[@]}" 2> /dev/null || true)
if [ -z "$OUT" ]; then
  printf 'ℹ️  No commits in this period.\n'
  exit 0
fi

DATA=$(printf '%s\n' "$OUT" | sort | uniq -c | awk '{ print $2 "\t" $1 }')
printf '📈 Commits per %s (last %s)\n\n' "$UNIT" "$COUNT"
printf '%s\n' "$DATA" | awk -F'\t' '
  { label[NR] = $1; n[NR] = $2; if ($2 > max) max = $2; total += $2 }
  END {
    for (i = 1; i <= NR; i++) {
      bar = ""
      len = (max > 0) ? int(n[i] * 40 / max) : 0
      for (j = 0; j < len; j++) bar = bar "#"
      printf "%-10s %3d %s\n", label[i], n[i], bar
    }
    printf "\nTotal: %d commit(s)\n", total
  }'
