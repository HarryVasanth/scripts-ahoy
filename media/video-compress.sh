#!/usr/bin/env bash
# Compress a video to an H.264/AAC MP4 file.
# Usage: video-compress [-q CRF] [-H HEIGHT] [-p PRESET] [-a KBPS] [-o DIR] [--force] [--replace] VIDEO...
# Needs: FFmpeg

set -euo pipefail
crf=23
height=1080
preset=medium
audio=128
outdir=
force=false
replace=false

usage() {
  cat <<'EOF'
Compress video with H.264 and AAC. The source stays unless --replace.
  -q CRF       Quality 0 to 51, lower is better (default: 23)
  -H HEIGHT    Maximum height (default: 1080)
  -p PRESET    x264 speed preset (default: medium)
  -a KBPS      Audio bitrate (default: 128)
  -o DIR       Output directory
  --force      Overwrite an existing output
  --replace    Replace the source file
  -h, --help   Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -q) crf=${2:-}; shift 2 || die "Option -q needs a value." ;;
    -H) height=${2:-}; shift 2 || die "Option -H needs a value." ;;
    -p) preset=${2:-}; shift 2 || die "Option -p needs a value." ;;
    -a) audio=${2:-}; shift 2 || die "Option -a needs a value." ;;
    -o) outdir=${2:-}; shift 2 || die "Option -o needs a value." ;;
    --force) force=true; shift ;;
    --replace) replace=true; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done
case "${crf}${height}${audio}" in
  *[!0-9]*) die "CRF, height and audio bitrate must be whole numbers." ;;
esac
[ "$crf" -le 51 ] || die "CRF must be 51 or less."
[ "$#" -gt 0 ] || { usage >&2; die "Give me at least one video."; }
command -v ffmpeg >/dev/null 2>&1 || die "FFmpeg is missing. Install it with: brew install ffmpeg, or sudo apt install ffmpeg."
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for src in "$@"; do
  [ -f "$src" ] || die "Not a file: $src"
  base=$(basename "$src")
  name=${base%.*}
  dir=$(dirname "$src")
  [ -z "$outdir" ] || dir=$outdir
  [ -d "$dir" ] || die "Output directory does not exist: $dir"
  if [ "$replace" = true ]; then
    dest="$dir/$name.mp4"
  else
    dest="$dir/$name-compressed.mp4"
  fi
  if [ "$replace" = false ] && [ -e "$dest" ] && [ "$force" = false ]; then
    die "Output exists: $dest (use --force to overwrite)"
  fi
  tmp="$tmpdir/out.mp4"
  printf '🎬 %s -> %s\n' "$src" "$dest" >&2
  before=$(wc -c < "$src")
  ffmpeg -hide_banner -loglevel error -nostdin -y -i "$src" \
    -vf "scale=-2:min(ih\,$height)" \
    -c:v libx264 -crf "$crf" -preset "$preset" \
    -c:a aac -b:a "${audio}k" -movflags +faststart "$tmp"
  mv -f "$tmp" "$dest"
  if [ "$replace" = true ] && [ "$src" != "$dest" ]; then rm -f "$src"; fi
  printf '✅ %s bytes before, %s bytes after.\n' "$before" "$(wc -c < "$dest")" >&2
done
