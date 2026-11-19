#!/usr/bin/env bash
# Build a table of contents from the headings in a Markdown file.
# Usage: markdown-toc.sh [-l LEVEL] [FILE]
# Note: keep headings plain for the cleanest links.

set -euo pipefail

maxlevel=3
file=""

usage() {
  cat << 'EOF'
Print a Markdown list of links to the headings in a file.
Usage: markdown-toc.sh [-l LEVEL] [FILE]

  -l LEVEL    deepest heading level to include (default: 3)
  -h, --help  show this help

Reads standard input when no FILE is given.
EOF
}

while (($# > 0)); do
  case "$1" in
    -l | --level)
      (($# >= 2)) || {
        printf 'error: %s needs a value\n' "$1" >&2
        exit 1
      }
      maxlevel="$2"
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
  shift
done

(($# <= 1)) || {
  printf 'error: give one file only\n' >&2
  exit 1
}
[[ "$maxlevel" =~ ^[1-6]$ ]] || {
  printf 'error: LEVEL must be 1 to 6\n' >&2
  exit 1
}
if (($# == 1)); then
  file="$1"
  [[ -r "$file" ]] || {
    printf 'error: cannot read %s\n' "$file" >&2
    exit 1
  }
fi

toc() {
  awk -v maxlevel="$maxlevel" '
    /^[[:space:]]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    /^#{1,6}[[:space:]]/ {
      line = $0
      level = 0
      while (substr(line, level + 1, 1) == "#") level++
      if (level > maxlevel) next
      text = substr(line, level + 1)
      sub(/^[[:space:]]+/, "", text)
      sub(/[[:space:]]+#+[[:space:]]*$/, "", text)
      gsub(/[`*_]/, "", text)
      anchor = tolower(text)
      gsub(/[^a-z0-9 _-]/, "", anchor)
      gsub(/ /, "-", anchor)
      indent = ""
      for (i = 1; i < level; i++) indent = indent "  "
      printf "%s- [%s](#%s)\n", indent, text, anchor
    }
  '
}

if [[ -n "$file" ]]; then
  toc < "$file"
else
  toc
fi
