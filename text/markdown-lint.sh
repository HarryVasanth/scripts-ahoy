#!/usr/bin/env bash
# Check Markdown files for common problems.
# Usage: markdown-lint.sh [FILE...]

set -euo pipefail

case "${1:-}" in
  -h|--help)
    cat <<'EOF'
Find simple Markdown problems.
Usage: markdown-lint.sh [FILE...]

The script checks for:
  - trailing spaces at the end of a line
  - a heading with no space after the hashes
  - a heading level that jumps by more than one
  - a link with an empty target

Reads standard input when no FILE is given.
Findings go to stderr. The exit code is 1 when any are found.
EOF
    exit 0 ;;
  -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
esac

for f in "$@"; do
  [[ -r "$f" ]] || { printf 'error: cannot read %s\n' "$f" >&2; exit 1; }
done

findings=$(awk '
  FNR == 1 { file = (FILENAME == "" ? "-" : FILENAME); prev = 0 }
  {
    if ($0 ~ /[ \t]+$/)
      printf "%s:%d: trailing whitespace\n", file, FNR
    if ($0 ~ /^#+[^# ]/)
      printf "%s:%d: heading needs a space after the hashes\n", file, FNR
    if ($0 ~ /^#+ /) {
      level = 0
      while (substr($0, level + 1, 1) == "#") level++
      if (prev > 0 && level > prev + 1)
        printf "%s:%d: heading jumps from level %d to %d\n", file, FNR, prev, level
      prev = level
    }
    if ($0 ~ /\]\([ \t]*\)/)
      printf "%s:%d: link has an empty target\n", file, FNR
  }
' "$@")

if [[ -z "$findings" ]]; then
  printf '✅ No Markdown problems found\n' >&2
  exit 0
fi

printf '%s\n' "$findings" >&2
count=$(printf '%s\n' "$findings" | wc -l | tr -d ' ')
printf '❌ %s problem(s) found\n' "$count" >&2
exit 1
