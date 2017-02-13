#!/usr/bin/env bash
# Turn text into a URL-friendly slug.
# Usage: slugify.sh [-s SEP] [TEXT...]
# Note: accents are dropped, not transliterated. Read stdin when no TEXT is given.

set -euo pipefail

sep="-"

usage() {
  cat <<'EOF'
Make a lowercase slug from text.
Usage: slugify.sh [-s SEP] [TEXT...]

  -s SEP      join words with this character: - or _ (default: -)
  -h, --help  show this help

Example: slugify.sh "Hello, World!"  gives  hello-world
EOF
}

while (($# > 0)); do
  case "$1" in
    -s|--separator)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      sep="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
  shift
done

[[ "$sep" == "-" || "$sep" == "_" ]] || { printf 'error: SEP must be - or _\n' >&2; exit 1; }

if (($# > 0)); then
  text="$*"
else
  text=$(cat)
fi

slug=$(printf '%s\n' "$text" |
  tr '[:upper:]' '[:lower:]' |
  tr '\n' ' ' |
  sed -E "s/[^a-z0-9]+/$sep/g; s/^$sep+//; s/$sep+\$//")

printf '%s\n' "$slug"
