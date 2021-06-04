#!/usr/bin/env bash
# Turn a JSON document into dotenv lines.
# Usage: json-to-env [-f FILE] [--prefix WORD] [--export]
# Needs: jq
# Note: Nested keys are joined with an underscore. Multi-line values stay escaped.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: json-to-env [-f FILE] [--prefix WORD] [--export]

Read JSON from a file or stdin, then print KEY=value lines.
Keys are upper case. Nested objects are flattened with an underscore.

  -f, --file FILE   Read this file. Default: stdin.
  --prefix WORD     Add WORD_ in front of every key.
  --export          Write "export KEY=value" lines.
  -h, --help        Show this help.

Example:
  json-to-env -f config.json --prefix APP
EOF
}

die() { printf '❌ %s\n' "$1" >&2; exit 1; }

# The jq program uses $ names, so no shell expansion must happen here.
# shellcheck disable=SC2016
program='
def flat($p):
  if type == "object" then to_entries[] | .key as $k | .value | flat(if $p == "" then $k else $p + "_" + $k end)
  else { key: $p, value: (if . == null then "\"\"" elif type == "string" then tojson
        elif type == "number" or type == "boolean" then tostring else tojson end) } end;
flat($prefix) | "\(.key)=\(.value)"
'

file=""
prefix=""
export=0
while (($# > 0)); do
  case "$1" in
    -f|--file|--prefix)
      (($# > 1)) || die "$1 needs a value."
      case "$1" in
        -f|--file) file="$2" ;;
        --prefix) prefix="$2" ;;
      esac
      shift ;;
    --export) export=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

command -v jq >/dev/null 2>&1 || die 'jq is not installed. Install it: https://jqlang.github.io/jq/'
[[ -z "$file" || -f "$file" ]] || die "File not found: $file"

tmp=$(mktemp "${TMPDIR:-/tmp}/json-to-env.XXXXXX")
trap 'rm -f "$tmp"' EXIT
if [[ -n "$file" ]]; then
  jq -r --arg prefix "$prefix" "$program" "$file" > "$tmp" || die 'The input is not valid JSON.'
else
  jq -r --arg prefix "$prefix" "$program" > "$tmp" || die 'The input is not valid JSON.'
fi

while IFS= read -r line; do
  if [[ -n "$line" ]]; then
    key=${line%%=*}
    value=${line#*=}
    key=$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]' | sed 's/[^A-Z0-9_]/_/g')
    [[ "$key" =~ ^[0-9] ]] && key="_$key"
    if ((export == 1)); then
      printf 'export %s=%s\n' "$key" "$value"
    else
      printf '%s=%s\n' "$key" "$value"
    fi
  fi
done < "$tmp"
