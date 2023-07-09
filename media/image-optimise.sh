#!/usr/bin/env bash
# Make images smaller with ImageMagick, with little visible loss.
# Usage: image-optimise [-q QUALITY] [-o DIR] [--force] [--replace] IMAGE...
# Needs: ImageMagick (magick, or convert on older systems)

set -euo pipefail
quality=82
outdir=
force=false
replace=false

usage() {
  cat <<'EOF'
Strip metadata and re-encode at a lower quality.
The source stays unless --replace. Output: NAME-optimised.EXT.
  -q QUALITY   Quality from 1 to 100 (default: 82)
  -o DIR       Output directory
  --force      Overwrite an existing output
  --replace    Replace the source file
  -h, --help   Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -q) quality=${2:-}; shift 2 || die "Option -q needs a value." ;;
    -o) outdir=${2:-}; shift 2 || die "Option -o needs a value." ;;
    --force) force=true; shift ;;
    --replace) replace=true; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

case "$quality" in ''|*[!0-9]*) die "Quality must be a whole number." ;; esac
[ "$quality" -ge 1 ] && [ "$quality" -le 100 ] || die "Quality must be from 1 to 100."
[ "$#" -gt 0 ] || { usage >&2; die "Give me at least one image."; }
im=(convert)
if command -v magick >/dev/null 2>&1; then im=(magick); fi
command -v "${im[0]}" >/dev/null 2>&1 || die "ImageMagick is missing. Install it with: brew install imagemagick, or sudo apt install imagemagick."
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for src in "$@"; do
  [ -f "$src" ] || die "Not a file: $src"
  base=$(basename "$src"); name=${base%.*}; ext=${base##*.}
  [ "$name" != "$base" ] || ext=""
  dir=$(dirname "$src"); [ -z "$outdir" ] || dir=$outdir
  [ -d "$dir" ] || die "Output directory does not exist: $dir"
  if [ "$replace" = true ]; then dest=$src
  elif [ -n "$ext" ]; then dest="$dir/$name-optimised.$ext"
  else dest="$dir/$name-optimised"; fi
  if [ "$replace" = false ] && [ -e "$dest" ] && [ "$force" = false ]; then
    die "Output exists: $dest (use --force to overwrite)"
  fi
  tmp="$tmpdir/out"; [ -z "$ext" ] || tmp="$tmpdir/out.$ext"
  before=$(wc -c < "$src")
  printf '🗜️  %s -> %s\n' "$src" "$dest" >&2
  "${im[@]}" "$src" -strip -quality "$quality" "$tmp"
  mv -f "$tmp" "$dest"
  printf '✅ %s bytes -> %s bytes.\n' "$before" "$(wc -c < "$dest")" >&2
done
