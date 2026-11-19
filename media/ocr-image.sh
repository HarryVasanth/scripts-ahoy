#!/usr/bin/env bash
# Read text from images with Tesseract.
# Usage: ocr-image [-l LANG] [-o FILE] [--force] IMAGE...
# Needs: Tesseract

set -euo pipefail

lang=eng
outfile=
force=false

usage() {
  cat << 'EOF'
Read text from images. Text goes to stdout unless -o is given.

Options:
  -l LANG      Tesseract language code (default: eng)
  -o FILE      Write all text to FILE instead of stdout
  --force      Overwrite an existing output file
  -h, --help   Show this help
EOF
}

die() {
  printf '❌ %s\n' "$*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    -l)
      lang=${2:-}
      shift 2 || die "Option -l needs a value."
      ;;
    -o)
      outfile=${2:-}
      shift 2 || die "Option -o needs a value."
      ;;
    --force)
      force=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

case "$lang" in
  '' | *[!A-Za-z0-9+_-]*) die "Language must look like eng or deu+eng." ;;
esac
[ "$#" -gt 0 ] || {
  usage >&2
  die "Give me at least one image."
}
command -v tesseract > /dev/null 2>&1 || die "Tesseract is missing. Install it with: brew install tesseract, or sudo apt install tesseract-ocr."

if [ -n "$outfile" ]; then
  [ -e "$outfile" ] && [ "$force" = false ] && die "Output exists: $outfile (use --force to overwrite)"
  : > "$outfile"
fi

count=0
for src in "$@"; do
  [ -f "$src" ] || die "Not a file: $src"
  count=$((count + 1))
  printf '🔎 Reading %s\n' "$src" >&2
  if [ -n "$outfile" ]; then
    [ "$count" -gt 1 ] && printf '\n--- %s ---\n' "$src" >> "$outfile"
    tesseract "$src" stdout -l "$lang" 2> /dev/null >> "$outfile"
  else
    if [ "$#" -gt 1 ]; then
      printf '--- %s ---\n' "$src"
    fi
    tesseract "$src" stdout -l "$lang" 2> /dev/null
  fi
done
