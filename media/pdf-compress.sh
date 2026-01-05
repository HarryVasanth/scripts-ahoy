#!/usr/bin/env bash
# Shrink a PDF with Ghostscript, keeping the text selectable.
# Usage: pdf-compress [-q PROFILE] [-o FILE] [--force] PDF
# Needs: Ghostscript

set -euo pipefail
profile=ebook
output=
force=false

usage() {
  cat <<'EOF'
Re-encode a PDF at a lower image quality. The source file never changes.
Default output: NAME-compressed.pdf next to the source.

Options:
  -q PROFILE   screen, ebook, printer or prepress (default: ebook)
  -o FILE      Output file name
  --force      Overwrite an existing output
  -h, --help   Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -q) profile=${2:-}; shift 2 || die "Option -q needs a value." ;;
    -o) output=${2:-}; shift 2 || die "Option -o needs a value." ;;
    --force) force=true; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

case "$profile" in
  screen|ebook|printer|prepress) ;;
  *) die "Profile must be screen, ebook, printer or prepress." ;;
esac
[ "$#" -eq 1 ] || { usage >&2; die "Give me exactly one PDF."; }
[ -f "$1" ] || die "Not a file: $1"
command -v gs >/dev/null 2>&1 || die "Ghostscript is missing. Install it with: brew install ghostscript, or sudo apt install ghostscript."
src=$1
if [ -z "$output" ]; then
  base=$(basename "$src")
  output="$(dirname "$src")/${base%.pdf}-compressed.pdf"
fi
[ -e "$output" ] && [ "$force" = false ] && die "Output exists: $output (use --force to overwrite)"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
before=$(wc -c < "$src")
printf '🗜️  %s (%s) -> %s\n' "$src" "$profile" "$output" >&2
gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 \
  -dPDFSETTINGS=/"$profile" -sOutputFile="$tmpdir/out.pdf" "$src"
mv -f "$tmpdir/out.pdf" "$output"
printf '✅ %s bytes -> %s bytes.\n' "$before" "$(wc -c < "$output")" >&2
