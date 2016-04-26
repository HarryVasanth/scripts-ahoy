#!/usr/bin/env bash
# Remove duplicate entries from a PATH-style colon list.
# Usage: dedupe-path.sh [--export] [-f FILE] [LIST]

set -euo pipefail

export_it=0
file=""

usage() {
  cat <<'EOF'
Drop repeated entries from a colon-separated path list.
Usage: dedupe-path.sh [--export] [-f FILE] [LIST]

  --export    print an export PATH= line instead of a bare list
  -f FILE     read the list from this file
  -h, --help  show this help

Without LIST the script uses the current PATH.
EOF
}

while (($# > 0)); do
  case "$1" in
    --export) export_it=1 ;;
    -f|--file)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      file="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
  shift
done

(($# <= 1)) || { printf 'error: give one list only\n' >&2; exit 1; }
[[ -z "$file" || $# -eq 0 ]] || { printf 'error: use -f FILE or LIST, not both\n' >&2; exit 1; }

if [[ -n "$file" ]]; then
  [[ -r "$file" ]] || { printf 'error: cannot read %s\n' "$file" >&2; exit 1; }
  IFS= read -r list < "$file" || true
elif (($# == 1)); then
  list="$1"
else
  list="$PATH"
fi

clean=$(printf '%s\n' "$list" | awk -F: '{
  for (i = 1; i <= NF; i++) {
    if ($i == "" || seen[$i]++) continue
    printf "%s%s", sep, $i
    sep = ":"
  }
}
END { print "" }')

if ((export_it)); then
  printf 'export PATH="%s"\n' "$clean"
else
  printf '%s\n' "$clean"
fi
