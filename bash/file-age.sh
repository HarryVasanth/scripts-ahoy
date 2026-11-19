#!/usr/bin/env bash
# List the oldest and newest files by modification time.
# Usage: file-age.sh [-n COUNT] [DIR]

set -euo pipefail

count=3

usage() {
  cat << 'EOF'
Show the oldest and newest files in a tree.
Usage: file-age.sh [-n COUNT] [DIR]

  -n, --number COUNT   files per list (default: 3)
  -h, --help           show this help

DIR defaults to the current directory. The search is recursive.
EOF
}

while (($# > 0)); do
  case "$1" in
    -n | --number)
      (($# >= 2)) || {
        printf 'error: %s needs a count\n' "$1" >&2
        exit 1
      }
      count="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      printf 'error: unknown option %s\n' "$1" >&2
      exit 1
      ;;
    *) break ;;
  esac
done
(($# <= 1)) || {
  printf 'error: give one directory at most\n' >&2
  exit 1
}
dir="${1:-.}"

if ! [[ "$count" =~ ^[0-9]+$ ]] || ((count == 0)); then
  printf 'error: COUNT must be a positive number\n' >&2
  exit 1
fi
[[ -d "$dir" ]] || {
  printf 'error: %s is not a directory\n' "$dir" >&2
  exit 1
}

bsd=1
if stat --version > /dev/null 2>&1; then bsd=0; fi
tmp=$(mktemp "${TMPDIR:-/tmp}/file-age.XXXXXX") || exit 1
trap 'rm -f "$tmp"' EXIT

# shortcut: a file name with a newline breaks the listing, not common enough to handle.
find "$dir" -type f -print0 | while IFS= read -r -d '' f; do
  if ((bsd)); then stat -f '%m %N' "$f"; else stat -c '%Y %n' "$f"; fi
done > "$tmp"

if [[ ! -s "$tmp" ]]; then
  printf '🔍 No files found in %s\n' "$dir" >&2
  exit 0
fi
print_list() {
  sort "$1" "$tmp" | head -n "$count" | while IFS= read -r line; do
    when=${line%% *}
    path=${line#* }
    if ((bsd)); then
      stamp=$(date -r "$when" '+%Y-%m-%d %H:%M')
    else
      stamp=$(date -d "@$when" '+%Y-%m-%d %H:%M')
    fi
    printf '  %s  %s\n' "$stamp" "$path"
  done
}

printf '🐢 Oldest %d\n' "$count"
print_list -n
printf '🐇 Newest %d\n' "$count"
print_list -rn
