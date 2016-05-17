#!/usr/bin/env bash
# Convert text between common naming cases.
# Usage: case-convert.sh --to STYLE [TEXT...]
# Note: read stdin when no TEXT is given.

set -euo pipefail

style=""
usage() {
  cat <<'EOF'
Change text to a chosen naming style.
Usage: case-convert.sh --to STYLE [TEXT...]

  --to STYLE  one of: lower, upper, title, snake, kebab, camel, pascal, constant
  -h, --help  show this help

Example: case-convert.sh --to snake "Hello world"  gives  hello_world
EOF
}

while (($# > 0)); do
  case "$1" in
    -t|--to)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      style="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
  shift
done
case "$style" in
  lower|upper|title|snake|kebab|camel|pascal|constant) ;;
  "") printf 'error: choose a style with --to\n' >&2; usage >&2; exit 1 ;;
  *) printf 'error: unknown style %s\n' "$style" >&2; exit 1 ;;
esac

if (($# > 0)); then
  text="$*"
else
  text=$(cat)
fi
printf '%s\n' "$text" | awk -v mode="$style" '
  function split_words(s, w,   i, c, cur, prev, n) {
    gsub(/[^A-Za-z0-9]+/, " ", s)
    sub(/^ +/, "", s)
    sub(/ +$/, "", s)
    n = 0; cur = ""; prev = ""
    for (i = 1; i <= length(s); i++) {
      c = substr(s, i, 1)
      if (c == " ") {
        if (cur != "") { w[++n] = cur; cur = "" }
        prev = ""
        continue
      }
      if (cur != "" && c ~ /[A-Z]/ && prev ~ /[a-z0-9]/) { w[++n] = cur; cur = "" }
      cur = cur c
      prev = c
    }
    if (cur != "") w[++n] = cur
    return n
  }
  function cap(s) { return toupper(substr(s, 1, 1)) substr(s, 2) }
  {
    if (mode == "lower") { print tolower($0); next }
    if (mode == "upper") { print toupper($0); next }
    n = split_words($0, w)
    out = ""
    for (i = 1; i <= n; i++) {
      part = tolower(w[i])
      if (mode == "title") { out = out (i > 1 ? " " : "") cap(part) }
      else if (mode == "snake") { out = out (i > 1 ? "_" : "") part }
      else if (mode == "kebab") { out = out (i > 1 ? "-" : "") part }
      else if (mode == "constant") { out = out (i > 1 ? "_" : "") toupper(part) }
      else if (mode == "camel") { out = out (i > 1 ? cap(part) : part) }
      else if (mode == "pascal") { out = out cap(part) }
    }
    print out
  }
'
