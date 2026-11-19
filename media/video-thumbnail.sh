#!/usr/bin/env bash
# Grab one frame from a video as a JPEG image.
# Usage: video-thumbnail [-t TIME] [-w WIDTH] [-o FILE] [--force] VIDEO
# Needs: FFmpeg

set -euo pipefail
time=00:00:01
width=
output=
force=false

usage() {
  cat << 'EOF'
Take a still image from one video. The video never changes.
Default output: NAME-thumb.jpg next to the video.

Options:
  -t TIME      Time of the frame, such as 5 or 00:00:05 (default: 1 second)
  -w WIDTH     Scale the image to this width (default: source width)
  -o FILE      Output file name
  --force      Overwrite an existing output
  -h, --help   Show this help
EOF
}

die() {
  printf '❌ %s\n' "$*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    -t)
      time=${2:-}
      shift 2 || die "Option -t needs a value."
      ;;
    -w)
      width=${2:-}
      shift 2 || die "Option -w needs a value."
      ;;
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

[ -n "$time" ] || die "Time cannot be empty."
[ -z "$width" ] || case "$width" in *[!0-9]*) die "Width must be a whole number." ;; esac
[ "$#" -eq 1 ] || {
  usage >&2
  die "Give me exactly one video."
}
[ -f "$1" ] || die "Not a file: $1"
command -v ffmpeg > /dev/null 2>&1 || die "FFmpeg is missing. Install it with: brew install ffmpeg, or sudo apt install ffmpeg."
src=$1
if [ -z "$output" ]; then
  base=$(basename "$src")
  output="$(dirname "$src")/${base%.*}-thumb.jpg"
fi
[ -e "$output" ] && [ "$force" = false ] && die "Output exists: $output (use --force to overwrite)"
args=(-hide_banner -loglevel error -nostdin -y -ss "$time" -i "$src")
[ -z "$width" ] || args+=(-vf "scale=$width:-2")
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
tmp="$tmpdir/${output##*/}"
printf '📸 %s at %s -> %s\n' "$src" "$time" "$output" >&2
ffmpeg "${args[@]}" -frames:v 1 -q:v 2 "$tmp"
mv -f "$tmp" "$output"
printf '✅ Wrote %s\n' "$output" >&2
