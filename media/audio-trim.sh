#!/usr/bin/env bash
# Trim an audio file without re-encoding it.
# Usage: audio-trim [-s START] [-d DURATION] [-o FILE] [--force] [--replace] AUDIO
# Needs: FFmpeg

set -euo pipefail
start=00:00:00
duration=
output=
force=false
replace=false

usage() {
  cat << 'EOF'
Cut a piece from one audio file. The codec stays the same.
The source stays unless --replace. Output: NAME-trimmed.EXT.
  -s START      Start time, such as 5 or 00:00:05 (default: 0)
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
  die "Give me exactly one audio file."
}
[ -f "$1" ] || die "Not a file: $1"
command -v ffmpeg > /dev/null 2>&1 || die "FFmpeg is missing. Install it with: brew install ffmpeg, or sudo apt install ffmpeg."
src=$1
base=$(basename "$src")
ext=${base##*.}
[ "$base" != "$ext" ] || die "The audio file needs an extension."
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
args=(-hide_banner -loglevel error -nostdin -y -ss "$start" -i "$src")
[ -z "$duration" ] || args+=(-t "$duration")
printf '✂️  %s -> %s\n' "$src" "$output" >&2
ffmpeg "${args[@]}" -c copy -avoid_negative_ts make_zero "$tmp"
mv -f "$tmp" "$output"
if [ "$replace" = true ] && [ "$src" != "$output" ]; then rm -f "$src"; fi
printf '✅ Wrote %s\n' "$output" >&2
