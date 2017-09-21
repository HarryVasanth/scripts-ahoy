#!/usr/bin/env bash
# Turn a video clip into a smooth GIF with a generated colour palette.
# Usage: gif-from-video [-s WIDTH] [-f FPS] [-t START] [-d DURATION] [-o FILE] [--force] VIDEO
# Needs: FFmpeg

set -euo pipefail

width=480
fps=12
start=0
duration=
output=
force=false

usage() {
  cat <<'EOF'
Build a GIF from one video. A two-pass palette keeps the colours clean.

Options:
  -s WIDTH      Output width in pixels (default: 480)
  -f FPS        Frames per second (default: 12)
  -t START      Start time, such as 0 or 00:00:05 (default: 0)
  -d DURATION   Clip length, such as 3 or 00:00:03 (default: to the end)
  -o FILE       Output file name (default: next to the video)
  --force       Overwrite an existing output file
  -h, --help    Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -s) width=${2:-}; shift 2 || die "Option -s needs a value." ;;
    -f) fps=${2:-}; shift 2 || die "Option -f needs a value." ;;
    -t) start=${2:-}; shift 2 || die "Option -t needs a value." ;;
    -d) duration=${2:-}; shift 2 || die "Option -d needs a value." ;;
    -o) output=${2:-}; shift 2 || die "Option -o needs a value." ;;
    --force) force=true; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

case "${width}${fps}" in
  *[!0-9]*) die "Width and FPS must be whole numbers." ;;
esac
[ -n "$start" ] || die "Start time cannot be empty."
[ "$#" -eq 1 ] || { usage >&2; die "Give me exactly one video."; }
[ -f "$1" ] || die "Not a file: $1"
command -v ffmpeg >/dev/null 2>&1 || die "FFmpeg is missing. Install it with: brew install ffmpeg, or sudo apt install ffmpeg."

src=$1
if [ -z "$output" ]; then
  base=$(basename "$src")
  output="$(dirname "$src")/${base%.*}.gif"
fi
[ -e "$output" ] && [ "$force" = false ] && die "Output exists: $output (use --force to overwrite)"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
palette="$tmpdir/palette.png"
trim=(-ss "$start")
if [ -n "$duration" ]; then
  trim+=(-t "$duration")
fi

printf '🌀 Reading %s\n' "$src" >&2
ffmpeg -hide_banner -loglevel error -nostdin -y "${trim[@]}" -i "$src" \
  -vf "fps=$fps,scale=$width:-1:flags=lanczos,palettegen=stats_mode=diff" "$palette"
printf '🎨 Writing %s\n' "$output" >&2
ffmpeg -hide_banner -loglevel error -nostdin -y "${trim[@]}" -i "$src" -i "$palette" \
  -lavfi "fps=$fps,scale=$width:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5" \
  "$output"
printf '✅ Wrote %s\n' "$output" >&2
