#!/usr/bin/env bash
# Combine images into one PDF, in the order given.
# Usage: image-to-pdf [-o FILE] [--force] IMAGE...
# Needs: ImageMagick (magick, or convert on older systems)

set -euo pipefail
output=images.pdf
force=false

usage() {
  cat << 'EOF'
Put each image on its own page. The first image becomes page one.
The source files never change.

Options:
  -o FILE      Output file name (default: images.pdf)
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
    -o)
      output=${2:-}
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

[ "$#" -gt 0 ] || {
  usage >&2
  die "Give me at least one image."
}
[ -e "$output" ] && [ "$force" = false ] && die "Output exists: $output (use --force to overwrite)"
images=()
for file in "$@"; do
  [ -f "$file" ] || die "Not a file: $file"
  images+=("$file")
done
if command -v magick > /dev/null 2>&1; then
  im=(magick)
elif command -v convert > /dev/null 2>&1; then
  im=(convert)
else
  die "ImageMagick is missing. Install it with: brew install imagemagick, or sudo apt install imagemagick."
fi
printf '📚 Writing %s images to %s\n' "${#images[@]}" "$output" >&2
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
tmp="$tmpdir/${output##*/}"
"${im[@]}" "${images[@]}" "$tmp"
mv -f "$tmp" "$output"
printf '✅ Wrote %s\n' "$output" >&2
