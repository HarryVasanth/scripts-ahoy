#!/usr/bin/env bash
# Build a contact sheet from many images in one grid.
# Usage: contact-sheet [-c COLUMNS] [-s SIZE] [-t TITLE] [-o FILE] [--force] IMAGE...
# Needs: ImageMagick (montage, or magick montage)

set -euo pipefail

columns=4
size=240
title=
output=contact-sheet.jpg
force=false

usage() {
  cat <<'EOF'
Place images in a grid and write one contact sheet.

Options:
  -c COLUMNS   Number of columns (default: 4)
  -s SIZE      Thumbnail size in pixels (default: 240)
  -t TITLE     Add a title above the grid
  -o FILE      Output file name (default: contact-sheet.jpg)
  --force      Overwrite an existing output file
  -h, --help   Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -c) columns=${2:-}; shift 2 || die "Option -c needs a value." ;;
    -s) size=${2:-}; shift 2 || die "Option -s needs a value." ;;
    -t) title=${2:-}; shift 2 || die "Option -t needs a value." ;;
    -o) output=${2:-}; shift 2 || die "Option -o needs a value." ;;
    --force) force=true; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

case "${columns}${size}" in
  *[!0-9]*) die "Columns and size must be whole numbers." ;;
esac
[ "$#" -gt 0 ] || { usage >&2; die "Give me at least one image."; }
[ -e "$output" ] && [ "$force" = false ] && die "Output exists: $output (use --force to overwrite)"

if command -v montage >/dev/null 2>&1; then
  im=(montage)
elif command -v magick >/dev/null 2>&1; then
  im=(magick montage)
else
  die "ImageMagick is missing. Install it with: brew install imagemagick, or sudo apt install imagemagick."
fi

args=(-thumbnail "${size}x${size}" -tile "${columns}x" -geometry "+4+4" -background '#f0f0f0')
if [ -n "$title" ]; then
  args+=(-title "$title")
fi

printf '🧩 Building %s from %s images\n' "$output" "$#" >&2
"${im[@]}" "${args[@]}" "$@" "$output"
printf '✅ Wrote %s\n' "$output" >&2
