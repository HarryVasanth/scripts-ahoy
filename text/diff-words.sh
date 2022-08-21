#!/usr/bin/env bash
# Show a word-level diff of two files.
# Usage: diff-words.sh FILE1 FILE2
# Needs: git

set -euo pipefail

usage() {
  cat <<'EOF'
Compare two files word by word.
Usage: diff-words.sh FILE1 FILE2

  -h, --help   show this help

Removed words appear as [-this-] and added words as {+this+}.
The output uses the plain word-diff format from git.

Example: diff-words.sh old.txt new.txt
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

(($# == 2)) || { printf 'error: give exactly two files\n' >&2; usage >&2; exit 1; }
for f in "$1" "$2"; do
  [[ -r "$f" ]] || { printf 'error: cannot read %s\n' "$f" >&2; exit 1; }
done
command -v git >/dev/null 2>&1 ||
  { printf 'error: git is not installed\n  macOS: install the command line tools\n  Linux: apt-get install git\n' >&2; exit 1; }

status=0
diff=$(git diff --no-index --word-diff=plain -- "$1" "$2") || status=$?

if ((status > 1)); then
  printf 'error: git diff failed with status %d\n' "$status" >&2
  exit 1
fi

if ((status == 0)); then
  printf '🟰 The files are the same\n'
  exit 0
fi

printf '%s\n' "$diff"
