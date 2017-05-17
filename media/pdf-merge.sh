#!/usr/bin/env bash
# Merge PDF files into one document, in the order given.
# Usage: pdf-merge [-o OUTPUT.pdf] [--force] PDF...
# Needs: pdfunite (poppler-utils), or Ghostscript

set -euo pipefail

output=merged.pdf
force=false

usage() {
  cat <<'EOF'
Merge PDF files. The first file becomes the first pages of the result.

Options:
  -o FILE      Output file name (default: merged.pdf)
  --force      Overwrite an existing output file
  -h, --help   Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -o) output=${2:-}; shift 2 || die "Option -o needs a value." ;;
    --force) force=true; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

[ "$#" -gt 0 ] || { usage >&2; die "Give me at least one PDF."; }
[ -e "$output" ] && [ "$force" = false ] && die "Output exists: $output (use --force to overwrite)"

inputs=()
for file in "$@"; do
  [ -f "$file" ] || die "Not a file: $file"
  case "$output" in
    "$file") die "The output file cannot be one of the inputs." ;;
  esac
  inputs+=("$file")
done

if command -v pdfunite >/dev/null 2>&1; then
  printf '📚 Merging %s files into %s\n' "$#" "$output" >&2
  pdfunite "${inputs[@]}" "$output"
elif command -v gs >/dev/null 2>&1; then
  printf '📚 Merging %s files into %s\n' "$#" "$output" >&2
  gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile="$output" "${inputs[@]}"
else
  die "No PDF tool found. Install poppler-utils, or Ghostscript."
fi

printf '✅ Wrote %s\n' "$output" >&2
