#!/usr/bin/env bash
# Rename many files with one sed pattern.
# Usage: batch-rename.sh [--apply] [-E] PATTERN REPLACEMENT FILE...
# Note: dry run is the default. Add --apply to move the files.

set -euo pipefail

apply=0
extended=0

usage() {
  cat << 'EOF'
Rename files by applying a sed expression to each name.
Usage: batch-rename.sh [--apply] [-E] PATTERN REPLACEMENT FILE...

  --apply     do the renames (without it, only print the plan)
  -E          use extended regular expressions
  -h, --help  show this help

Example: batch-rename.sh -E 'IMG_([0-9]+)' 'photo-\1' *.JPG
EOF
}

while (($# > 0)); do
  case "$1" in
    --apply)
      apply=1
      shift
      ;;
    -E | --extended)
      extended=1
      shift
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
(($# >= 3)) || {
  printf 'error: give PATTERN, REPLACEMENT and at least one FILE\n' >&2
  usage >&2
  exit 1
}

pattern="$1"
replacement="$2"
shift 2
changes=0
for f in "$@"; do
  if [[ ! -e "$f" ]]; then
    printf '⚠️  Skip %s: not found\n' "$f" >&2
    continue
  fi

  dir=$(dirname "$f")
  base=$(basename "$f")
  if ((extended)); then
    new=$(printf '%s\n' "$base" | sed -E "s/$pattern/$replacement/")
  else
    new=$(printf '%s\n' "$base" | sed "s/$pattern/$replacement/")
  fi

  if [[ -z "$new" ]]; then
    printf '⚠️  Skip %s: the new name is empty\n' "$f" >&2
    continue
  fi
  if [[ "$new" == "$base" ]]; then
    continue
  fi

  target="$dir/$new"
  if [[ -e "$target" ]]; then
    printf '⚠️  Skip %s: %s already exists\n' "$f" "$target" >&2
    continue
  fi

  if ((apply)); then
    mv -- "$f" "$target"
    printf '✅ %s → %s\n' "$f" "$target" >&2
  else
    printf '📝 %s → %s\n' "$f" "$target" >&2
  fi
  changes=$((changes + 1))
done

if ((apply)); then
  printf '🎉 Renamed %d file(s)\n' "$changes" >&2
else
  printf 'ℹ️  %d planned rename(s). Run again with --apply to do them.\n' "$changes" >&2
fi
