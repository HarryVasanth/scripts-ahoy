#!/usr/bin/env bash
# Print Makefile targets that have a description comment.
# Usage: makefile-help [-f FILE]

set -euo pipefail

usage() {
  cat << 'EOF'
Usage: makefile-help [-f FILE]

List every target that has a "## description" comment on the same line.
The default file is Makefile in the current directory.

  -f FILE     Read FILE instead of Makefile.
  -h, --help  Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

file="Makefile"
while (($# > 0)); do
  case "$1" in
    -f)
      shift
      (($# > 0)) || die 'Option -f needs a file.'
      file="$1"
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "Unknown option: $1" ;;
    *) die "Unexpected argument: $1" ;;
  esac
  shift
done

[[ -f "$file" ]] || die "File not found: $file"
if ! grep -q '##' "$file"; then
  printf 'ℹ️  No targets have a ## description in %s.\n' "$file" >&2
  exit 0
fi

printf '📋 Targets in %s\n\n' "$file"
awk '
  /^[A-Za-z0-9_.%-][A-Za-z0-9_.%-]*[ \t]*:/ && /##/ {
    split($0, parts, "##")
    name = parts[1]
    sub(/[ \t]*:.*/, "", name)
    desc = parts[2]
    sub(/^[ \t]+/, "", desc)
    sub(/[ \t]+$/, "", desc)
    printf "  %-22s %s\n", name, desc
  }
' "$file"
