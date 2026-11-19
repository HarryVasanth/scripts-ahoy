#!/usr/bin/env bash
# Trim a video, copying the streams when the format allows.
# Usage: video-trim [-s START] [-d DURATION] [-o FILE] [--force] [--replace] VIDEO
# Needs: FFmpeg
# Note: A stream copy cannot cut between keyframes. Use a re-encode for exact cuts.

set -euo pipefail
start=00:00:00
duration=
output=
force=false
replace=false

usage() {
  cat << 'EOF'
Cut a piece from one video. The source stays unless --replace.
Output: NAME-trimmed.EXT.
  -s START      Start time, such as 10 or 00:00:10 (default: 0)
  -d DURATION   Clip length, such as 30 or 00:00:30 (default: to the end)
  -o FILE       Output file name
  --force       Overwrite an existing output
  --replace     Replace the source file
  -h, --help    Show this help
EOF
}

die() {
  printf '❌ %s\n' "$*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    -s)
      start=${2:-}
      shift 2 || die "Option -s needs a value."
      ;;
    -d)
      duration=${2:-}
      shift 2 || die "Option -d needs a value."
      ;;
    -o)
      output=${2:-}
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

[ -n "$start" ] || die "Start time cannot be empty."
[ "$#" -eq 1 ] || {
  usage >&2
  die "Give me exactly one video."
}
[ -f "$1" ] || die "Not a file: $1"
command -v ffmpeg > /dev/null 2>&1 || die "FFmpeg is missing. Install it with: brew install ffmpeg, or sudo apt install ffmpeg."
src=$1
base=$(basename "$src")
ext=${base##*.}
[ "$base" != "$ext" ] || die "The video needs a file extension."
if [ -z "$output" ]; then
  if [ "$replace" = true ]; then
    output=$src
  else output="$(dirname "$src")/${base%.*}-trimmed.$ext"; fi
fi
if [ -e "$output" ] && [ "$force" = false ] && [ "$replace" = false ]; then
  die "Output exists: $output (use --force to overwrite)"
fi
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
tmp="$tmpdir/out.$ext"
args=(-hide_banner -loglevel error -nostdin -y -i "$src" -ss "$start")
[ -z "$duration" ] || args+=(-t "$duration")
printf '✂️  %s -> %s\n' "$src" "$output" >&2
if ! ffmpeg "${args[@]}" -c copy -avoid_negative_ts make_zero "$tmp" 2> /dev/null; then
  printf '⚠️  Stream copy failed. Re-encoding instead.\n' >&2
  ffmpeg "${args[@]}" -c:v libx264 -crf 20 -c:a aac "$tmp"
fi
mv -f "$tmp" "$output"
if [ "$replace" = true ] && [ "$src" != "$output" ]; then rm -f "$src"; fi
printf '✅ Wrote %s\n' "$output" >&2
