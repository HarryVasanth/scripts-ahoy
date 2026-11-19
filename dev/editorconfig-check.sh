#!/usr/bin/env bash
# Check basic .editorconfig rules against files.
# Usage: editorconfig-check [FILE...]

set -euo pipefail

usage() {
  printf 'Usage: editorconfig-check [FILE...]\n\n'
  printf 'Check indent style, line endings, trailing whitespace and the final newline\n'
  printf 'against .editorconfig. With no FILE, check tracked files.\n'
  printf 'Only "*" and "*.ext" sections are read.\n\n'
  printf '  -h, --help  Show this help.\n'
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
esac
[[ -f .editorconfig ]] || die 'No .editorconfig in the current directory.'

files=("$@")
if ((${#files[@]} == 0)); then
  command -v git > /dev/null 2>&1 || die 'Pass file names, or install git.'
  git rev-parse --is-inside-work-tree > /dev/null 2>&1 || die 'Pass file names.'
  while IFS= read -r path; do files+=("$path"); done < <(git ls-files)
fi

tmp=$(mktemp -d "${TMPDIR:-/tmp}/editorconfig-check.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

awk '
  /^[[:space:]]*[#;]|^[[:space:]]*$/ { next }
  /^[[:space:]]*\[/ {
    s = $0; gsub(/^[[:space:]]*\[|\][[:space:]]*$/, "", s); gsub(/[{}]/, "", s)
    n = split(s, parts, ","); next
  }
  /=/ {
    key = $0; sub(/=.*/, "", key); gsub(/[[:space:]]/, "", key); value = $0; sub(/^[^=]*=/, "", value); gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    for (i = 1; i <= n; i++) {
      ext = parts[i]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", ext)
      if (ext == "*") { print 0 "\t" key "\t*\t" value; continue }
      if (ext !~ /^\*/) ext = "*." ext
      if (ext ~ /^\*\./) print 1 "\t" key "\t" substr(ext, 2) "\t" value
    }
  }
' .editorconfig | LC_ALL=C sort -k1,1 > "$tmp/rules"
problems=0
for file in "${files[@]}"; do
  [[ -f "$file" ]] || continue
  grep -Iq . "$file" 2> /dev/null || continue
  base=${file##*/}
  ext=""
  case "$base" in *.*) ext=".${base##*.}" ;; esac
  settings=$(awk -F'\t' -v e="$ext" '
    $2 == "indent_style" && ($3 == e || $3 == "*") { s = $4 }
    $2 == "insert_final_newline" && ($3 == e || $3 == "*") { f = $4 }
    $2 == "trim_trailing_whitespace" && ($3 == e || $3 == "*") { t = $4 }
    $2 == "end_of_line" && ($3 == e || $3 == "*") { l = $4 }
    END { print s "\t" f "\t" t "\t" l }
  ' "$tmp/rules")
  IFS=$'\t' read -r style final trail eol <<< "$settings"
  msg=""
  if [[ "$trail" == true ]] && grep -q '[[:blank:]]$' "$file"; then msg="$msg trailing-whitespace"; fi
  if [[ "$final" == true && -n "$(tail -c 1 "$file")" ]]; then msg="$msg no-final-newline"; fi
  if [[ "$eol" == lf ]] && LC_ALL=C grep -q "$(printf '\r')" "$file"; then msg="$msg crlf"; fi
  if [[ "$style" == space ]] && grep -q "^$(printf '\t')" "$file"; then msg="$msg tab-indent"; fi
  if [[ -n "$msg" ]]; then
    printf '❌ %s:%s\n' "$file" "$msg"
    problems=1
  fi
done

if ((problems != 0)); then
  printf '❌ Some files break .editorconfig.\n' >&2
  exit 1
fi
printf '✅ All checked files follow .editorconfig.\n'
