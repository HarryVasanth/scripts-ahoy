#!/usr/bin/env bash
# Extract a page range from a PDF, or split it into single pages.
# Usage: pdf-split [-p RANGE] [--each] [-o DIR] [--force] PDF
# Needs: Ghostscript; pdfseparate (poppler-utils) for --each

set -euo pipefail
range=
each=false
outdir=
force=false

usage() {
  cat <<'EOF'
Copy pages from one PDF. The source file never changes.
  -p RANGE     Pages to keep, such as 3 or 2-5
  --each       Write one PDF for each page instead
  -o DIR       Output directory
  --force      Overwrite existing output files
  -h, --help   Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }
while [ $# -gt 0 ]; do
  case "$1" in
    -p) range=${2:-}; shift 2 || die "Option -p needs a value." ;;
    --each) each=true; shift ;;
    -o) outdir=${2:-}; shift 2 || die "Option -o needs a value." ;;
    --force) force=true; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

[ "$#" -eq 1 ] || { usage >&2; die "Give me exactly one PDF."; }
[ -f "$1" ] || die "Not a file: $1"
[ "$each" = true ] || [ -n "$range" ] || { usage >&2; die "Give -p RANGE, or --each."; }
[ "$each" = false ] || [ -z "$range" ] || die "Use -p or --each, not both."
command -v gs >/dev/null 2>&1 || die "Ghostscript is missing. Install it with: brew install ghostscript, or sudo apt install ghostscript."
pdf=$1; dir=$(dirname "$pdf")
[ -z "$outdir" ] || dir=$outdir
[ -d "$dir" ] || die "Output directory does not exist: $dir"
base=$(basename "$pdf"); name=${base%.pdf}; [ "$name" != "$base" ] || name=$base

if [ "$each" = true ]; then
  command -v pdfseparate >/dev/null 2>&1 || die "pdfseparate is missing. Install poppler-utils."
  if [ "$force" = false ] && ls "$dir/$name-page-"*.pdf >/dev/null 2>&1; then
    die "Page files exist in $dir (use --force to overwrite)"
  fi
  printf '📄 Splitting %s into single pages.\n' "$pdf" >&2
  pdfseparate "$pdf" "$dir/$name-page-%d.pdf"
  printf '✅ Wrote page files in %s\n' "$dir" >&2
  exit 0
fi

case "$range" in *-*) first=${range%-*}; last=${range#*-} ;; *) first=$range; last=$range ;; esac
case "${first}${last}" in ''|*[!0-9]*) die "Pages must be numbers, such as 3 or 2-5." ;; esac
[ "$first" -ge 1 ] || die "The first page must be 1 or more."
[ "$last" -ge "$first" ] || die "The last page must not be before the first."
if [ "$first" = "$last" ]; then dest="$dir/$name-page-$first.pdf"
else dest="$dir/$name-pages-$first-$last.pdf"; fi
[ -e "$dest" ] && [ "$force" = false ] && die "Output exists: $dest (use --force to overwrite)"
tmpdir=$(mktemp -d); trap 'rm -rf "$tmpdir"' EXIT
printf '📄 %s pages %s-%s -> %s\n' "$pdf" "$first" "$last" "$dest" >&2
gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dFirstPage="$first" -dLastPage="$last" \
  -sOutputFile="$tmpdir/out.pdf" "$pdf"
mv -f "$tmpdir/out.pdf" "$dest"
printf '✅ Wrote %s\n' "$dest" >&2
