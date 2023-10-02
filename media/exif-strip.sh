#!/usr/bin/env bash
# Remove metadata from images, such as GPS and camera details.
# Usage: exif-strip [-o DIR] [--keep-orientation] [--force] [--replace] IMAGE...
# Needs: ExifTool

set -euo pipefail

outdir=
keep_orientation=false
force=false
replace=false

usage() {
  cat <<'EOF'
Remove all metadata from images. The source stays in place unless --replace.

Options:
  -o DIR             Write results to DIR (default: next to the source)
  --keep-orientation Copy the Orientation tag back after the strip
  --force            Overwrite an existing output file
  --replace          Replace the source file instead of making a copy
  -h, --help         Show this help

Default output name: NAME-clean.EXT
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -o) outdir=${2:-}; shift 2 || die "Option -o needs a value." ;;
    --keep-orientation) keep_orientation=true; shift ;;
    --force) force=true; shift ;;
    --replace) replace=true; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

[ "$#" -gt 0 ] || { usage >&2; die "Give me at least one image."; }
command -v exiftool >/dev/null 2>&1 || die "ExifTool is missing. Install it with: brew install exiftool, or sudo apt install libimage-exiftool-perl."

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for src in "$@"; do
  [ -f "$src" ] || die "Not a file: $src"
  base=$(basename "$src")
  name=${base%.*}
  ext=${base##*.}
  [ "$name" != "$base" ] || ext=""
  if [ "$replace" = true ]; then
    dest=$src
  else
    dir=$(dirname "$src")
    [ -n "$outdir" ] && dir=$outdir
    [ -d "$dir" ] || die "Output directory does not exist: $dir"
    if [ -n "$ext" ]; then
      dest="$dir/$name-clean.$ext"
    else
      dest="$dir/$name-clean"
    fi
    if [ -e "$dest" ] && [ "$force" = false ]; then
      die "Output exists: $dest (use --force to overwrite)"
    fi
  fi
  tmp="$tmpdir/out"
  [ -n "$ext" ] && tmp="$tmpdir/out.$ext"
  cp "$src" "$tmp"
  printf '🧽 %s -> %s\n' "$src" "$dest" >&2
  exiftool -q -q -all= -overwrite_original "$tmp"
  if [ "$keep_orientation" = true ]; then
    exiftool -q -q -tagsfromfile "$src" -Orientation -overwrite_original "$tmp"
  fi
  mv -f "$tmp" "$dest"
done
