#!/usr/bin/env bash
# Convert audio files to another format.
# Usage: audio-convert [-f FORMAT] [-b BITRATE] [-o DIR] [--force] [--replace] AUDIO...
# Needs: FFmpeg

set -euo pipefail
format=mp3
bitrate=192k
outdir=
force=false
replace=false

usage() {
  cat <<'EOF'
Convert audio with FFmpeg. The source stays unless --replace.
  -f FORMAT    mp3, m4a, aac, ogg, opus, flac or wav (default: mp3)
  -b BITRATE   Bitrate for lossy formats (default: 192k)
  -o DIR       Output directory
  --force      Overwrite an existing output
  --replace    Replace the source file
  -h, --help   Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -f) format=${2:-}; shift 2 || die "Option -f needs a value." ;;
    -b) bitrate=${2:-}; shift 2 || die "Option -b needs a value." ;;
    -o) outdir=${2:-}; shift 2 || die "Option -o needs a value." ;;
    --force) force=true; shift ;;
    --replace) replace=true; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

case "$format" in
  mp3) codec=(-c:a libmp3lame -b:a "$bitrate") ;;
  m4a|aac) codec=(-c:a aac -b:a "$bitrate") ;;
  ogg) codec=(-c:a libvorbis -q:a 5) ;;
  opus) codec=(-c:a libopus -b:a "$bitrate") ;;
  flac) codec=(-c:a flac) ;;
  wav) codec=(-c:a pcm_s16le) ;;
  *) die "Unsupported format: $format" ;;
esac
case "$bitrate" in
  ''|*[!0-9k]*) die "Bitrate must look like 192k." ;;
esac
[ "$#" -gt 0 ] || { usage >&2; die "Give me at least one audio file."; }
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
  dest="$dir/$name.$format"
  if [ "$replace" = false ] && [ -e "$dest" ] && [ "$force" = false ]; then
    die "Output exists: $dest (use --force to overwrite)"
  fi
  tmp="$tmpdir/out.$format"
  printf '🎵 %s -> %s\n' "$src" "$dest" >&2
  ffmpeg -hide_banner -loglevel error -nostdin -y -i "$src" -vn "${codec[@]}" "$tmp"
  mv -f "$tmp" "$dest"
  if [ "$replace" = true ] && [ "$src" != "$dest" ]; then rm -f "$src"; fi
done
