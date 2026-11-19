#!/usr/bin/env bash
# Convert screenshots to WebP, lossless by default for crisp text.
# Usage: screenshot-webp [-q QUALITY] [-o DIR] [--force] [--replace] IMAGE...
# Needs: ImageMagick (magick, or convert on older systems)

set -euo pipefail
quality=
outdir=
force=false
replace=false

usage() {
  cat << 'EOF'
Convert images to WebP. Lossless is the default, which suits screenshots.
  -q QUALITY   Use lossy compression at this quality, 0 to 100
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
    -q)
      quality=${2:-}
      shift 2 || die "Option -q needs a value."
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

if [ -n "$quality" ]; then
  case "$quality" in
    '' | *[!0-9]*) die "Quality must be a whole number from 0 to 100." ;;
  esac
  [ "$quality" -le 100 ] || die "Quality must be 100 or less."
fi
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
  dir=$(dirname "$src")
  [ -z "$outdir" ] || dir=$outdir
  [ -d "$dir" ] || die "Output directory does not exist: $dir"
  dest="$dir/$name.webp"
  if [ "$replace" = false ] && [ -e "$dest" ] && [ "$force" = false ]; then
    die "Output exists: $dest (use --force to overwrite)"
  fi
  tmp="$tmpdir/out.webp"
  printf '📸 %s -> %s\n' "$src" "$dest" >&2
  if [ -n "$quality" ]; then
    "${im[@]}" "$src" -quality "$quality" "$tmp"
  else
    "${im[@]}" "$src" -define webp:lossless=true -quality 100 "$tmp"
  fi
  mv -f "$tmp" "$dest"
  if [ "$replace" = true ] && [ "$src" != "$dest" ]; then rm -f "$src"; fi
done
