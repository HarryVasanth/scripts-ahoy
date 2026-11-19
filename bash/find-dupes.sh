#!/usr/bin/env bash
# Find duplicate files by SHA-256 in a directory tree.
# Usage: find-dupes.sh [DIR]
# Needs: sha256sum (Linux) or shasum (macOS)

set -euo pipefail

usage() {
  cat << 'EOF'
Find duplicate files by content.
Usage: find-dupes.sh [DIR]

  -h, --help   show this help

DIR defaults to the current directory. The search is recursive.
Each group of files with the same SHA-256 hash is printed together.
EOF
}

case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    printf 'error: unknown option %s\n' "$1" >&2
    exit 1
    ;;
esac
(($# <= 1)) || {
  printf 'error: give one directory at most\n' >&2
  exit 1
}
dir="${1:-.}"
[[ -d "$dir" ]] || {
  printf 'error: %s is not a directory\n' "$dir" >&2
  exit 1
}

if command -v sha256sum > /dev/null 2>&1; then
  hashtool="sha256sum"
elif command -v shasum > /dev/null 2>&1; then
  hashtool="shasum"
else
  printf 'error: no SHA-256 tool found\n  macOS: shasum ships with the system\n  Linux: install coreutils\n' >&2
  exit 1
fi

tmp=$(mktemp "${TMPDIR:-/tmp}/find-dupes.XXXXXX") || exit 1
trap 'rm -f "$tmp"' EXIT

# shortcut: file names with a tab or newline break the grouping, rare in practice.
find "$dir" -type f -print0 | while IFS= read -r -d '' f; do
  if [[ "$hashtool" == "sha256sum" ]]; then
    sum=$(sha256sum "$f")
  else
    sum=$(shasum -a 256 "$f")
  fi
  printf '%s\t%s\n' "${sum%% *}" "$f"
done > "$tmp"

groups=$(awk -F'\t' '{ n[$1]++ } END { c = 0; for (h in n) if (n[h] > 1) c++; print c }' "$tmp")
if ((groups == 0)); then
  printf '✅ No duplicate files found in %s\n' "$dir" >&2
  exit 0
fi

sort -k1,1 "$tmp" | awk -F'\t' '
  $1 == prev {
    if (!shown) { printf "📦 %s\n   %s\n", prev, prevpath; shown = 1 }
    printf "   %s\n", $2
    next
  }
  { prev = $1; prevpath = $2; shown = 0 }
'
printf '🔎 %d duplicate group(s) found\n' "$groups" >&2
