#!/usr/bin/env bash
# Encode or decode a file with base64.
# Usage: base64-file.sh [-d] [-o OUT] [FILE]

set -euo pipefail

decode=0
out=""

usage() {
  cat << 'EOF'
Encode a file to base64, or decode it back.
Usage: base64-file.sh [-d] [-o OUT] [FILE]

  -d, --decode    decode the input instead of encoding it
  -o, --output    write the result to OUT instead of stdout
  -h, --help      show this help

Reads standard input when no FILE is given.
Example: base64-file.sh -o photo.b64 photo.jpg
EOF
}

while (($# > 0)); do
  case "$1" in
    -d | --decode)
      decode=1
      shift
      ;;
    -o | --output)
      (($# >= 2)) || {
        printf 'error: %s needs a file name\n' "$1" >&2
        exit 1
      }
      out="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      printf 'error: unknown option %s\n' "$1" >&2
      exit 1
      ;;
    *) break ;;
  esac
done

(($# <= 1)) || {
  printf 'error: give one file at most\n' >&2
  usage >&2
  exit 1
}
if (($# == 1)); then
  [[ -r "$1" ]] || {
    printf 'error: cannot read %s\n' "$1" >&2
    exit 1
  }
  src="$1"
else
  src="/dev/stdin"
fi

# GNU base64 uses --decode. The base64 in macOS uses -D.
if printf '' | base64 --decode > /dev/null 2>&1; then
  decode_flag="--decode"
else
  decode_flag="-D"
fi

if ((decode)); then
  if [[ -n "$out" ]]; then
    base64 "$decode_flag" < "$src" > "$out"
  else
    base64 "$decode_flag" < "$src"
  fi
else
  if [[ -n "$out" ]]; then
    base64 < "$src" > "$out"
  else
    base64 < "$src"
  fi
fi

if [[ -n "$out" ]]; then
  printf '✅ Wrote %s\n' "$out" >&2
fi
