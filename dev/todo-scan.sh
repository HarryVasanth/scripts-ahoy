#!/usr/bin/env bash
# Find TODO, FIXME, HACK and XXX notes in a tree of source files.
# Usage: todo-scan [--count] [--tag TAG] [path]

set -euo pipefail

usage() {
  cat << 'EOF'
Usage: todo-scan [--count] [--tag TAG] [path]

Print every note as file:line:text. The default path is the current directory.
The scan skips .git, node_modules, vendor, dist, build, target and .venv.

  --count     Show a count per file instead of each note.
  --tag TAG   Scan for one tag only (for example FIXME).
  -h, --help  Show this help.
EOF
}

count_only=0
tags='TODO|FIXME|HACK|XXX'
root='.'

while (($# > 0)); do
  case "$1" in
    --count) count_only=1 ;;
    --tag)
      if (($# < 2)); then
        printf '❌ --tag needs a word.\n' >&2
        exit 1
      fi
      tags="$2"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      printf '❌ Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
    *) root="$1" ;;
  esac
  shift
done

if [[ ! "$tags" =~ ^[A-Za-z]+(\|[A-Za-z]+)*$ ]]; then
  printf '❌ Use letters only for the tag: %s\n' "$tags" >&2
  exit 1
fi

if [[ ! -e "$root" ]]; then
  printf '❌ Path not found: %s\n' "$root" >&2
  exit 1
fi

hits=$(mktemp "${TMPDIR:-/tmp}/todo-scan.XXXXXX")
trap 'rm -f "$hits"' EXIT

find "$root" \
  \( -name .git -o -name node_modules -o -name vendor -o -name dist \
  -o -name build -o -name target -o -name .venv \) -prune \
  -o -type f -print0 \
  | xargs -0 grep -nHEI "($tags)[[:space:]:]" -- > "$hits" 2> /dev/null || true

if [[ ! -s "$hits" ]]; then
  printf '🎉 No %s notes found in %s.\n' "$tags" "$root" >&2
  exit 0
fi

total=$(wc -l < "$hits")
total=${total//[[:space:]]/}

if ((count_only == 1)); then
  printf '📊 %s note(s) in %s.\n' "$total" "$root" >&2
  awk '{ i = index($0, ":"); print substr($0, 1, i - 1) }' "$hits" \
    | sort | uniq -c | sort -rn
else
  printf '📊 %s note(s) in %s.\n' "$total" "$root" >&2
  cat "$hits"
fi
