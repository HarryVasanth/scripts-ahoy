#!/usr/bin/env bash
# Show the end of several log files with a label on each line.
# Usage: log-tail.sh [-n LINES] [-f] FILE...

set -euo pipefail

lines=10
follow=0
files=()

usage() {
  cat <<'EOF'
Tail one or more log files.
Usage: log-tail.sh [-n LINES] [-f] FILE...

  -n, --lines LINES   number of lines to show (default: 10)
  -f, --follow        keep watching for new lines
  -h, --help          show this help

Each line gets a [file] label, so mixed output stays clear.
EOF
}

while (($# > 0)); do
  case "$1" in
    -n|--lines)
      (($# >= 2)) || { printf 'error: %s needs a count\n' "$1" >&2; exit 1; }
      lines="$2"; shift 2 ;;
    -f|--follow) follow=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) files+=("$1"); shift ;;
  esac
done

[[ "$lines" =~ ^[0-9]+$ ]] ||
  { printf 'error: LINES must be a number\n' >&2; exit 1; }
((${#files[@]} > 0)) || { printf 'error: give at least one file\n' >&2; usage >&2; exit 1; }

for f in "${files[@]}"; do
  [[ -r "$f" ]] || { printf 'error: cannot read %s\n' "$f" >&2; exit 1; }
done

if ((follow)); then
  printf '👀 Following %d file(s). Press Ctrl-C to stop.\n' "${#files[@]}" >&2
  exec tail -n "$lines" -f "${files[@]}"
fi

for f in "${files[@]}"; do
  printf '📄 %s\n' "$f"
  tail -n "$lines" "$f" | awk -v label="[$f] " '{ print label $0 }'
done
