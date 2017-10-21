#!/usr/bin/env bash
# Shift every timestamp in a SubRip (SRT) subtitle file.
# Usage: subtitle-shift [-s SECONDS] [-o FILE] [--force] [--replace] SRT

set -euo pipefail
offset=0
output=
force=false
replace=false

usage() {
  cat <<'EOF'
Move all subtitles earlier or later. Positive values add time.
The source stays unless --replace. Output: NAME-shifted.srt.
  -s SECONDS    Shift by this many seconds, such as 1.5 or -2 (default: 0)
  -o FILE       Output file name
  --force       Overwrite an existing output
  --replace     Replace the source file
  -h, --help    Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -s) offset=${2:-}; shift 2 || die "Option -s needs a value." ;;
    -o) output=${2:-}; shift 2 || die "Option -o needs a value." ;;
    --force) force=true; shift ;;
    --replace) replace=true; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

case "$offset" in ''|*[!0-9.+-]*) die "Offset must be a number of seconds, such as 1.5 or -2." ;; esac
[ "$#" -eq 1 ] || { usage >&2; die "Give me exactly one SRT file."; }
[ -f "$1" ] || die "Not a file: $1"
src=$1
if [ -z "$output" ]; then
  if [ "$replace" = true ]; then output=$src
  else output="$(dirname "$src")/$(basename "$src" .srt)-shifted.srt"; fi
fi
if [ -e "$output" ] && [ "$force" = false ] && [ "$replace" = false ]; then
  die "Output exists: $output (use --force to overwrite)"
fi
tmpdir=$(mktemp -d); trap 'rm -rf "$tmpdir"' EXIT

printf '⏱️  %s by %s seconds -> %s\n' "$src" "$offset" "$output" >&2
awk -v off="$offset" '
function toms(t, p) { split(t, p, /[:,]/); return (p[1] * 3600 + p[2] * 60 + p[3]) * 1000 + p[4] + off * 1000 }
function stamp(v, h, m, s, f) {
  v = int(v); if (v < 0) v = 0
  f = v % 1000; v = int(v / 1000); s = v % 60; v = int(v / 60)
  m = v % 60; h = int(v / 60)
  return sprintf("%02d:%02d:%02d,%03d", h, m, s, f)
}
{ sub(/\r$/, "")
  if (index($0, "-->") > 0) {
    split($0, p, /[ ]*-->[ ]*/)
    print stamp(toms(p[1])) " --> " stamp(toms(p[2]))
  } else print }' "$src" > "$tmpdir/out.srt"
mv -f "$tmpdir/out.srt" "$output"
printf '✅ Wrote %s\n' "$output" >&2
