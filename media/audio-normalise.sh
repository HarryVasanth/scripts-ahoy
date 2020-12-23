#!/usr/bin/env bash
# Normalise audio loudness to the EBU R128 standard with FFmpeg.
# Usage: audio-normalise [-i LUFS] [-t TP] [-o DIR] [--force] [--replace] AUDIO...
# Needs: FFmpeg
# Since: 2016-09
# shortcut: single-pass loudnorm, upgrade to a two-pass measure for music albums.

set -euo pipefail
lufs=-16
peak=-1.5
outdir=
force=false
replace=false

usage() {
  cat <<'EOF'
Set every file to a common loudness for podcasts, radio and web video.
The source stays unless --replace. Output: NAME-normalised.EXT.
  -i LUFS      Target loudness from -70 to -5 (default: -16, good for podcasts)
  -t TP        True peak limit in dBTP (default: -1.5)
  -o DIR       Output directory
  --force      Overwrite an existing output
  --replace    Replace the source file
  -h, --help   Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -i) lufs=${2:-}; shift 2 || die "Option -i needs a value." ;;
    -t) peak=${2:-}; shift 2 || die "Option -t needs a value." ;;
    -o) outdir=${2:-}; shift 2 || die "Option -o needs a value." ;;
    --force) force=true; shift ;;
    --replace) replace=true; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

case "$lufs" in ''|*[!0-9.-]*) die "Loudness must be a number, such as -16." ;; esac
case "$peak" in ''|*[!0-9.-]*) die "True peak must be a number, such as -1.5." ;; esac
[ "$#" -gt 0 ] || { usage >&2; die "Give me at least one audio file."; }
command -v ffmpeg >/dev/null 2>&1 || die "FFmpeg is missing. Install it with: brew install ffmpeg, or sudo apt install ffmpeg."
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for src in "$@"; do
  [ -f "$src" ] || die "Not a file: $src"
  base=$(basename "$src"); name=${base%.*}; ext=${base##*.}
  [ "$name" != "$base" ] || ext=""
  dir=$(dirname "$src"); [ -z "$outdir" ] || dir=$outdir
  [ -d "$dir" ] || die "Output directory does not exist: $dir"
  if [ "$replace" = true ]; then dest=$src
  elif [ -n "$ext" ]; then dest="$dir/$name-normalised.$ext"
  else dest="$dir/$name-normalised"; fi
  if [ "$replace" = false ] && [ -e "$dest" ] && [ "$force" = false ]; then
    die "Output exists: $dest (use --force to overwrite)"
  fi
  tmp="$tmpdir/out"; [ -z "$ext" ] || tmp="$tmpdir/out.$ext"
  printf '🔊 %s -> %s\n' "$src" "$dest" >&2
  ffmpeg -hide_banner -loglevel error -nostdin -y -i "$src" \
    -af "loudnorm=I=${lufs}:TP=${peak}:LRA=11" -ar 48000 "$tmp"
  mv -f "$tmp" "$dest"
done
