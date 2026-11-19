#!/usr/bin/env bash
# Show the object store and working tree size.
# Usage: repo-size.sh [-h]
# Needs: git, du

set -euo pipefail

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    *) die "unknown option $1" ;;
  esac
done

git rev-parse --git-dir > /dev/null 2>&1 || die "this is not a git repository."

human() {
  awk -v kb="$1" 'BEGIN {
    if (kb >= 1048576) printf "%.2f GB\n", kb / 1048576
    else if (kb >= 1024) printf "%.1f MB\n", kb / 1024
    else printf "%d KB\n", kb
  }'
}

ROOT=$(git rev-parse --show-toplevel 2> /dev/null || printf '.')
GIT_KB=$(du -sk "$(git rev-parse --git-dir)" 2> /dev/null | awk '{ print $1 }')

WT_KB=0
if [ "$(git ls-files 2> /dev/null | wc -l | tr -d ' ')" -gt 0 ]; then
  WT_KB=$(git ls-files -z | xargs -0 du -k 2> /dev/null | awk '{ total += $1 } END { print total + 0 }')
fi

printf '🔎 Repository size\n\n'
printf '  %s\n\n' "$ROOT"
printf '  %-16s %s\n' 'Working tree' "$(human "${WT_KB:-0}")"
printf '  %-16s %s\n' 'Git folder' "$(human "${GIT_KB:-0}")"

git count-objects -v 2> /dev/null | awk -F': ' '
  function human(kb) {
    if (kb >= 1048576) return sprintf("%.2f GB", kb / 1048576)
    if (kb >= 1024) return sprintf("%.1f MB", kb / 1024)
    return kb " KB"
  }
  $1 == "count" { loose = $2 }
  $1 == "size" { loose_kb = $2 }
  $1 == "in-pack" { packed = $2 }
  $1 == "size-pack" { packed_kb = $2 }
  END {
    printf "  %-16s %s object(s), %s\n", "Loose objects", loose + 0, human(loose_kb + 0)
    printf "  %-16s %s object(s), %s\n", "Packed objects", packed + 0, human(packed_kb + 0)
  }
'

printf '\nℹ️  Run git gc to pack loose objects and reduce the store.\n'
