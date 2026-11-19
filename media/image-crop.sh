#!/usr/bin/env bash
# Crop an image to a geometry, keeping the rest of the image.
# Usage: image-crop [-g GEOMETRY] [-o DIR] [--force] [--replace] IMAGE...
# Needs: ImageMagick (magick, or convert on older systems)

set -euo pipefail
geometry=800x600+0+0
outdir=
force=false
replace=false

usage() {
  cat << 'EOF'
Cut a rectangle from images. The source stays unless --replace.
Output: NAME-cropped.EXT.
  -g GEOMETRY   Width x height, with an optional offset (default: 800x600+0+0)
                For example: 640x480+10+20
  -o DIR        Output directory
  --force       Overwrite an existing output
  --replace     Replace the source file
  -h, --help    Show this help
EOF
}

die() {
  printf '❌ %s\n' "$*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    -g)
      geometry=${2:-}
      shift 2 || die "Option -g needs a value."
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

case "$geometry" in [0-9]*x[0-9]*) ;; *) die "Geometry must look like 640x480 or 640x480+10+20." ;; esac
[ "$#" -gt 0 ] || {
  usage >&2
  die "Give me at least one image."
}
im=(convert)
if command -v magick > /dev/null 2>&1; then im=(magick); fi
command -v "${im[0]}" > /dev/null 2>&1 || die "ImageMagick is missing. Install it with: brew install imagemagick, or sudo apt install imagemagick."
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for src in "$@"; do
  [ -f "$src" ] || die "Not a file: $src"
  base=$(basename "$src")
  name=${base%.*}
  ext=${base##*.}
  [ "$name" != "$base" ] || ext=""
  dir=$(dirname "$src")
  [ -z "$outdir" ] || dir=$outdir
  [ -d "$dir" ] || die "Output directory does not exist: $dir"
  if [ "$replace" = true ]; then
    dest=$src
  elif [ -n "$ext" ]; then
    dest="$dir/$name-cropped.$ext"
  else dest="$dir/$name-cropped"; fi
  if [ "$replace" = false ] && [ -e "$dest" ] && [ "$force" = false ]; then
    die "Output exists: $dest (use --force to overwrite)"
  fi
  tmp="$tmpdir/out"
  [ -z "$ext" ] || tmp="$tmpdir/out.$ext"
  printf '✂️  %s -> %s\n' "$src" "$dest" >&2
  "${im[@]}" "$src" -crop "$geometry" +repage "$tmp"
  mv -f "$tmp" "$dest"
done
