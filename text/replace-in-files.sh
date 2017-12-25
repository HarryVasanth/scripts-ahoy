#!/usr/bin/env bash
# Replace text in many files, with a safe preview first.
# Usage: replace-in-files.sh [--apply] [-E] PATTERN REPLACEMENT FILE...
# Note: dry run is the default. Add --apply to write the files.
# Note: PATTERN is a sed regular expression.

set -euo pipefail

apply=0
extended=0
tmp=""

usage() {
  cat <<'EOF'
Find and replace text across files.
Usage: replace-in-files.sh [--apply] [-E] PATTERN REPLACEMENT FILE...

  --apply     write the changes (without it, only show which files change)
  -E          use extended regular expressions
  -h, --help  show this help

Example: replace-in-files.sh --apply -E 'old name' 'new name' *.md
EOF
}

while (($# > 0)); do
  case "$1" in
    --apply) apply=1; shift ;;
    -E|--extended) extended=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
done

(($# >= 3)) || { printf 'error: give PATTERN, REPLACEMENT and at least one FILE\n' >&2; usage >&2; exit 1; }

pattern="$1"
replacement="$2"
shift 2

for f in "$@"; do
  [[ -f "$f" ]] || { printf 'error: %s is not a file\n' "$f" >&2; exit 1; }
done

tmp=$(mktemp "${TMPDIR:-/tmp}/replace.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT

changed=0
for f in "$@"; do
  if ((extended)); then
    sed -E "s/$pattern/$replacement/g" "$f" > "$tmp"
  else
    sed "s/$pattern/$replacement/g" "$f" > "$tmp"
  fi

  if cmp -s "$f" "$tmp"; then
    continue
  fi

  if ((apply)); then
    cat "$tmp" > "$f"
    printf '✏️  Updated %s\n' "$f" >&2
  else
    printf '📝 Would update %s\n' "$f" >&2
  fi
  changed=$((changed + 1))
done

if ((apply)); then
  printf '🎉 Changed %d file(s)\n' "$changed" >&2
else
  printf 'ℹ️  %d file(s) would change. Run again with --apply.\n' "$changed" >&2
fi
