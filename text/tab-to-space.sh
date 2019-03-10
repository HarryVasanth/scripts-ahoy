#!/usr/bin/env bash
# Convert tabs to spaces, or spaces to tabs.
# Usage: tab-to-space.sh [-s] [-w WIDTH] [FILE...]

set -euo pipefail

to_tabs=0
width=4

usage() {
  cat <<'EOF'
Change tabs into spaces, or spaces into tabs.
Usage: tab-to-space.sh [-s] [-w WIDTH] [FILE...]

  -s, --spaces-to-tabs   reverse the direction
  -w, --width WIDTH      tab width (default: 4)
  -h, --help             show this help

Reads standard input when no FILE is given.
The result goes to stdout, so redirect it to save a new file.
EOF
}

while (($# > 0)); do
  case "$1" in
    -s|--spaces-to-tabs) to_tabs=1; shift ;;
    -w|--width)
      (($# >= 2)) || { printf 'error: %s needs a width\n' "$1" >&2; exit 1; }
      width="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
done

if ! [[ "$width" =~ ^[0-9]+$ ]] || ((width == 0)); then
  printf 'error: WIDTH must be a positive number\n' >&2
  exit 1
fi

for f in "$@"; do
  [[ -r "$f" ]] || { printf 'error: cannot read %s\n' "$f" >&2; exit 1; }
done

if ((to_tabs)); then
  unexpand -a -t "$width" "$@"
else
  expand -t "$width" "$@"
fi
