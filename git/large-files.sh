#!/usr/bin/env bash
# Find the largest files in the git history.
# Usage: large-files.sh [-n COUNT] [-h]
# Needs: git

set -euo pipefail

COUNT=10

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n) [ "$#" -ge 2 ] || die "-n needs a number."; COUNT=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option $1" ;;
  esac
done

case "$COUNT" in
  ''|*[!0-9]*|0) die "-n needs a number above zero." ;;
esac

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "this is not a git repository."
git rev-parse --verify -q HEAD >/dev/null || { printf 'ℹ️  No commits yet.\n'; exit 0; }

printf '🔎 Largest blobs in history\n\n'
git rev-list --objects --all |
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' 2>/dev/null |
  awk '$1 == "blob" { size = $3; $1 = $2 = $3 = ""; sub(/^ +/, ""); print size "\t" $0 }' |
  sort -rn |
  head -n "$COUNT" |
  awk -F'\t' '{ kb = $1 / 1024; if (kb >= 1024) printf "%8.2f MB  %s\n", kb / 1024, $2; else printf "%8.1f KB  %s\n", kb, $2 }' || true
