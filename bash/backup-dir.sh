#!/usr/bin/env bash
# Make a dated tar.gz backup of a directory and prune old copies.
# Usage: backup-dir.sh [-o OUTDIR] [-k KEEP] DIR
# Note: the archive holds the directory itself, not its full path.

set -euo pipefail

outdir="."
keep=0
partial=""

usage() {
  cat <<'EOF'
Back up one directory into a dated tar.gz file.
Usage: backup-dir.sh [-o OUTDIR] [-k KEEP] DIR

  -o OUTDIR   where to write the archive (default: current directory)
  -k KEEP     keep this many old archives of DIR (default: keep all)
  -h, --help  show this help
EOF
}

while (($# > 0)); do
  case "$1" in
    -o|--outdir)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      outdir="$2"; shift 2 ;;
    -k|--keep)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      keep="$2"
      [[ "$keep" =~ ^[0-9]+$ ]] || { printf 'error: KEEP must be a number\n' >&2; exit 1; }
      shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
done

(($# == 1)) || { printf 'error: give exactly one directory\n' >&2; usage >&2; exit 1; }
command -v tar >/dev/null 2>&1 || { printf 'error: tar is needed. Install tar with your package manager.\n' >&2; exit 1; }

dir="${1%/}"
[[ -d "$dir" ]] || { printf 'error: %s is not a directory\n' "$dir" >&2; exit 1; }

name=$(basename "$dir")
parent=$(dirname "$dir")
mkdir -p "$outdir"
archive="$outdir/$name-$(date +%Y%m%d-%H%M%S).tar.gz"

if [[ -e "$archive" ]]; then
  printf 'error: %s already exists. Try again in one second.\n' "$archive" >&2
  exit 1
fi

cleanup() {
  if [[ -n "$partial" && -f "$partial" ]]; then
    rm -f -- "$partial"
  fi
}
trap cleanup EXIT

printf '📦 Backing up %s ...\n' "$dir" >&2
partial="$archive"
tar -czf "$partial" -C "$parent" "$name"
partial=""
printf '%s\n' "$archive"

if ((keep > 0)); then
  find "$outdir" -maxdepth 1 -type f -name "$name-*.tar.gz" -exec ls -1t {} + |
    tail -n +"$((keep + 1))" |
    while IFS= read -r old; do
      rm -f -- "$old"
      printf '🧹 Removed old backup %s\n' "$old" >&2
    done
fi
