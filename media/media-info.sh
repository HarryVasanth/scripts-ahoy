#!/usr/bin/env bash
# Show a quick summary of media files: format, duration, size and streams.
# Usage: media-info FILE...
# Needs: FFprobe (ships with FFmpeg)

set -euo pipefail

usage() {
  cat << 'EOF'
Print a short report for each media file. Data goes to stdout.
EOF
}

die() {
  printf '❌ %s\n' "$*" >&2
  exit 1
}

case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
  --) shift ;;
esac

[ "$#" -gt 0 ] || {
  usage >&2
  die "Give me at least one file."
}
command -v ffprobe > /dev/null 2>&1 || die "FFprobe is missing. Install it with: brew install ffmpeg, or sudo apt install ffmpeg."

for file in "$@"; do
  [ -f "$file" ] || die "Not a file: $file"
  printf '📄 %s\n' "$file"

  fmt=$(ffprobe -v error -show_entries format=format_long_name -of csv=p=0 "$file" 2> /dev/null || true)
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$file" 2> /dev/null || true)
  secs=${dur%%.*}
  case "$secs" in
    '' | *[!0-9]*) shown="unknown" ;;
    *) shown=$(printf '%02d:%02d:%02d' $((secs / 3600)) $(((secs % 3600) / 60)) $((secs % 60))) ;;
  esac
  printf '   Format:   %s\n' "${fmt:-unknown}"
  printf '   Duration: %s\n' "$shown"
  printf '   Size:     %s\n' "$(du -h "$file" | awk '{print $1}')"

  video=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height,r_frame_rate -of csv=p=0 "$file" 2> /dev/null || true)
  if [ -n "$video" ]; then
    IFS=, read -r vcodec vw vh vrate <<< "$video"
    vfps=$(awk -F/ '{printf "%.2f", $1 / ($2 ? $2 : 1)}' <<< "$vrate")
    printf '   Video:    %s, %sx%s, %s fps\n' "$vcodec" "$vw" "$vh" "$vfps"
  else
    printf '   Video:    none\n'
  fi

  audio=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,channels,sample_rate -of csv=p=0 "$file" 2> /dev/null || true)
  if [ -n "$audio" ]; then
    IFS=, read -r acodec arate achannels <<< "$audio"
    printf '   Audio:    %s, %s channel(s), %s Hz\n' "$acodec" "$achannels" "$arate"
  else
    printf '   Audio:    none\n'
  fi
done
