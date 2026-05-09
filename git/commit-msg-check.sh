#!/usr/bin/env bash
# Check commit message format in a range.
# Usage: commit-msg-check.sh [-r RANGE] [-l MAX] [-h]
# Needs: git

set -euo pipefail

RANGE=
MAX=72
FAIL=0
TOTAL=0

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -r) [ "$#" -ge 2 ] || die "-r needs a range."; RANGE=$2; shift 2 ;;
    -l) [ "$#" -ge 2 ] || die "-l needs a number."; MAX=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option $1" ;;
  esac
done

case "$MAX" in
  ''|*[!0-9]*|0) die "-l needs a number above zero." ;;
esac
git rev-parse --git-dir >/dev/null 2>&1 || die "this is not a git repository."
if [ -z "$RANGE" ]; then
  if git rev-parse --abbrev-ref -q '@{u}' >/dev/null 2>&1; then
    RANGE='@{u}..HEAD'
  else
    RANGE=HEAD
  fi
fi
git rev-list --count "$RANGE" >/dev/null 2>&1 || die "bad range: $RANGE"
printf '🔎 Checking commit messages in %s\n\n' "$RANGE"
while IFS= read -r sha; do
  TOTAL=$((TOTAL + 1))
  msg=$(git log -1 --format=%B "$sha" 2>/dev/null)
  subject=$(printf '%s\n' "$msg" | head -n 1)
  second=$(printf '%s\n' "$msg" | sed -n '2p')
  problems=

  if [ "${#subject}" -gt "$MAX" ]; then
    problems="$problems subject is longer than $MAX"
  fi
  case "$subject" in
    *.) problems="$problems subject ends with a full stop" ;;
  esac
  case "$subject" in
    [[:space:]]*) problems="$problems subject starts with white space" ;;
    *[[:space:]]) problems="$problems subject ends with white space" ;;
  esac
  if [ -n "$second" ]; then
    problems="$problems body needs a blank line after the subject"
  fi
  if [ -n "$problems" ]; then
    FAIL=$((FAIL + 1))
    printf '⚠️  %s  %s\n     %s\n' "${sha:0:8}" "$subject" "$problems"
  fi
done < <(git rev-list "$RANGE")

printf '\n%s commit(s) checked, %s with problems.\n' "$TOTAL" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
