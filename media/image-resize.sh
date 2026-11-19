#!/usr/bin/env bash
# Resize images to fit inside a box, keeping each aspect ratio.
# Usage: image-resize [-w WIDTH] [-H HEIGHT] [-o DIR] [--force] [--replace] IMAGE...
# Needs: ImageMagick (magick, or convert on older systems)

set -euo pipefail
width=1920
height=1080
outdir=
force=false
replace=false

usage() {
  cat << 'EOF'
Resize images to fit a box. Images are never enlarged.
Default output: NAME-resized.EXT next to the source.
  -w WIDTH     Maximum width (default: 1920)
  -H HEIGHT    Maximum height (default: 1080)
  -o DIR       Output directory
  --force      Overwrite an existing output
  --replace    Replace the source file
  -h, --help   Show this help
EOF
}

die() {
  printf '❌ %s\n' "$*" >&2
  exit 1
}
while [ $# -gt 0 ]; do
  case "$1" in
    -w)
      width=${2:-}
      shift 2 || die "Option -w needs a value."
      ;;
    -H)
      height=${2:-}
      shift 2 || die "Option -H needs a value."
      ;;
    -o)
      outdir=${2:-}
      shift 2 || die "Option -o needs a value."
      ;;
    --force)
      force=true
      shift
      ;;
    --replace)
      replace=true
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
case "${width}${height}" in
  *[!0-9]*) die "Width and height must be whole numbers." ;;
esac
[ "$#" -gt 0 ] || {
  usage >&2
  die "Give me at least one image."
}
if command -v magick > /dev/null 2>&1; then
  im=(magick)
elif command -v convert > /dev/null 2>&1; then
  im=(convert)
else
  die "ImageMagick is missing. Install it with: brew install imagemagick, or sudo apt install imagemagick."
fi
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
      dest="$dir/$name-resized.$ext"
    else
      dest="$dir/$name-resized"
    fi
    if [ -e "$dest" ] && [ "$force" = false ]; then
      die "Output exists: $dest (use --force to overwrite)"
    fi
  fi
  tmp="$tmpdir/out"
  [ -n "$ext" ] && tmp="$tmpdir/out.$ext"
  printf '🖼️  %s -> %s\n' "$src" "$dest" >&2
  "${im[@]}" "$src" -resize "${width}x${height}>" "$tmp"
  mv -f "$tmp" "$dest"
done
