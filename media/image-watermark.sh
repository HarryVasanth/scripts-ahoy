#!/usr/bin/env bash
# Add a text watermark to an image.
# Usage: image-watermark -t TEXT [-p GRAVITY] [-s POINTS] [-o DIR] [--force] [--replace] IMAGE...
# Needs: ImageMagick (magick, or convert on older systems)

set -euo pipefail
text=
gravity=southeast
points=36
outdir=
force=false
replace=false

usage() {
  cat << 'EOF'
Write a light text mark on images. The source stays unless --replace.
Output: NAME-watermarked.EXT.
  -t TEXT       Watermark text (required)
  -p GRAVITY    A corner such as southeast (default: southeast)
  -s POINTS     Text size in points (default: 36)
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
    -t)
      text=${2:-}
      shift 2 || die "Option -t needs a value."
      ;;
    -p)
      gravity=${2:-}
      shift 2 || die "Option -p needs a value."
      ;;
    -s)
      points=${2:-}
      shift 2 || die "Option -s needs a value."
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

[ -n "$text" ] || {
  usage >&2
  die "Give me the watermark text with -t."
}
case "$points" in '' | *[!0-9]*) die "Text size must be a whole number." ;; esac
case "$gravity" in northwest | north | northeast | west | center | east | southwest | south | southeast) ;;
*) die "Gravity must be a corner or edge, such as southeast." ;; esac
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
  if [ "$replace" = true ]; then
    dest=$src
  elif [ -n "$ext" ]; then
    dest="$dir/$name-watermarked.$ext"
  else dest="$dir/$name-watermarked"; fi
  if [ "$replace" = false ] && [ -e "$dest" ] && [ "$force" = false ]; then
    die "Output exists: $dest (use --force to overwrite)"
  fi
  tmp="$tmpdir/out"
  [ -z "$ext" ] || tmp="$tmpdir/out.$ext"
  printf '💧 %s -> %s\n' "$src" "$dest" >&2
  "${im[@]}" "$src" -gravity "$gravity" -pointsize "$points" \
    -fill 'rgba(255,255,255,0.65)' -stroke 'rgba(0,0,0,0.35)' -strokewidth 1 -annotate +20+20 "$text" "$tmp"
  mv -f "$tmp" "$dest"
done
