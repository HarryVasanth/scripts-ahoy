#!/usr/bin/env bash
# Add an SPDX licence header to source files, or check that one is present.
# Usage: license-header [--check] <licence-id> <path>...
set -euo pipefail

usage() {
  cat << 'EOF'
Usage: license-header [--check] <licence-id> <path>...

Add an SPDX line and a copyright line to each supported file.
A file that already has an SPDX line is skipped.

  --check    Report files without a header. Exit 1 if any is missing.
  -h, --help Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

prefix_for() {
  case "${1##*.}" in
    sh | bash | zsh | py | rb | yaml | yml | toml | tf | hcl | conf | ini | env | mk) printf '#' ;;
    js | jsx | ts | tsx | mjs | cjs | c | h | cc | cpp | hpp | rs | go | java | kt | swift | cs | php | scala) printf '//' ;;
    sql) printf '%s' '--' ;;
    *) return 1 ;;
  esac
}

add_header() {
  local file="$1" prefix="$2" first
  first=$(head -n 1 "$file")
  [[ "$first" == '#!'* ]] || first=""
  {
    [[ -z "$first" ]] || printf '%s\n' "$first"
    printf '%s SPDX-License-Identifier: %s\n' "$prefix" "$spdx"
    printf '%s Copyright (c) %s The Authors\n' "$prefix" "$year"
    if [[ -n "$first" ]]; then tail -n +2 "$file"; else cat "$file"; fi
  } > "$tmp"
  cat "$tmp" > "$file"
}

check=0
paths=()
tmp=""
while (($# > 0)); do
  case "$1" in
    --check) check=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "Unknown option: $1" ;;
    *) paths+=("$1") ;;
  esac
  shift
done
((${#paths[@]} >= 2)) || {
  usage >&2
  die 'Pass a licence ID and at least one path.'
}
spdx="${paths[0]}"
[[ "$spdx" =~ ^[A-Za-z0-9.+-]+$ ]] || die "Not a valid SPDX licence ID: $spdx"
paths=("${paths[@]:1}")
trap '[[ -z "$tmp" ]] || rm -f "$tmp"' EXIT
year=$(date +%Y)
missing=0
while IFS= read -r file; do
  prefix=$(prefix_for "$file") || continue
  grep -q 'SPDX-License-Identifier' "$file" 2> /dev/null && continue
  if ((check == 1)); then
    printf '❌ Missing header: %s\n' "$file"
    missing=$((missing + 1))
  else
    tmp=$(mktemp "${TMPDIR:-/tmp}/licence.XXXXXX")
    add_header "$file" "$prefix"
    rm -f "$tmp"
    tmp=""
    printf '✨ Added header: %s\n' "$file"
  fi
done < <(for p in "${paths[@]}"; do
  if [[ -d "$p" ]]; then
    find "$p" -type f
  elif [[ -f "$p" ]]; then
    printf '%s\n' "$p"
  else printf '⚠️  Not found: %s\n' "$p" >&2; fi
done)
((check == 0)) && {
  printf '✅ Headers added.\n' >&2
  exit 0
}
((missing == 0)) || die "$missing file(s) need a header."
printf '✅ Every supported file has a header.\n' >&2
