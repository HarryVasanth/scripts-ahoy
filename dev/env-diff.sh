#!/usr/bin/env bash
# Compare the keys of two dotenv files without showing secret values.
# Usage: env-diff [--strict] <file-a> <file-b>
set -euo pipefail

usage() {
  cat << 'EOF'
Usage: env-diff [--strict] <file-a> <file-b>

Show keys that exist in one file only, and keys with different values.
Values are never printed. Comments and blank lines are ignored.

  --strict   Exit 1 when the files differ. Useful in CI.
  -h, --help Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

keys_of() {
  sed -n 's/^[[:space:]]*\(export[[:space:]][[:space:]]*\)\{0,1\}\([A-Za-z_][A-Za-z0-9_]*\)[[:space:]]*=.*/\2/p' "$1" \
    | LC_ALL=C sort -u
}

value_of() {
  sed -n "s/^[[:space:]]*\(export[[:space:]][[:space:]]*\)\{0,1\}${2}[[:space:]]*=[[:space:]]*//p" "$1" \
    | tail -n 1 | sed 's/[[:space:]]*$//' | tr -d '\r'
}

strict=0
files=()
while (($# > 0)); do
  case "$1" in
    --strict) strict=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "Unknown option: $1" ;;
    *) files+=("$1") ;;
  esac
  shift
done

((${#files[@]} == 2)) || {
  usage >&2
  die 'Pass exactly two files.'
}
a="${files[0]}"
b="${files[1]}"
[[ -f "$a" ]] || die "File not found: $a"
[[ -f "$b" ]] || die "File not found: $b"

tmp=$(mktemp -d "${TMPDIR:-/tmp}/env-diff.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
keys_of "$a" > "$tmp/a"
keys_of "$b" > "$tmp/b"
printf '📄 %s: %s keys\n' "$a" "$(wc -l < "$tmp/a" | tr -d '[:space:]')"
printf '📄 %s: %s keys\n' "$b" "$(wc -l < "$tmp/b" | tr -d '[:space:]')"

different=0
comm -23 "$tmp/a" "$tmp/b" > "$tmp/only_a"
if [[ -s "$tmp/only_a" ]]; then
  printf '\n➕ Only in %s:\n' "$a"
  sed 's/^/   /' "$tmp/only_a"
  different=1
fi
comm -13 "$tmp/a" "$tmp/b" > "$tmp/only_b"
if [[ -s "$tmp/only_b" ]]; then
  printf '\n➖ Only in %s:\n' "$b"
  sed 's/^/   /' "$tmp/only_b"
  different=1
fi
comm -12 "$tmp/a" "$tmp/b" > "$tmp/common"
: > "$tmp/changed"
while IFS= read -r key; do
  [[ "$(value_of "$a" "$key")" == "$(value_of "$b" "$key")" ]] || printf '%s\n' "$key" >> "$tmp/changed"
done < "$tmp/common"
if [[ -s "$tmp/changed" ]]; then
  printf '\n🔄 Different values:\n'
  sed 's/^/   /' "$tmp/changed"
  different=1
fi
((different == 1)) || {
  printf '\n✅ The files match.\n'
  exit 0
}
((strict == 1)) && exit 1
exit 0
