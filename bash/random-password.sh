#!/usr/bin/env bash
# Make strong random passwords from /dev/urandom.
# Usage: random-password.sh [-l LENGTH] [-c COUNT] [--no-symbols]

set -euo pipefail

length=20
count=1
chars='A-Za-z0-9@#%+=_.-'

usage() {
  cat << 'EOF'
Print random passwords, one per line.
Usage: random-password.sh [-l LENGTH] [-c COUNT] [--no-symbols]

  -l LENGTH      characters per password (default: 20, max: 256)
  -c COUNT       number of passwords (default: 1)
  --no-symbols   letters and digits only
  -h, --help     show this help
EOF
}

while (($# > 0)); do
  case "$1" in
    -l | --length)
      (($# >= 2)) || {
        printf 'error: %s needs a value\n' "$1" >&2
        exit 1
      }
      length="$2"
      shift
      ;;
    -c | --count)
      (($# >= 2)) || {
        printf 'error: %s needs a value\n' "$1" >&2
        exit 1
      }
      count="$2"
      shift
      ;;
    --no-symbols) chars='A-Za-z0-9' ;;
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
  shift
done

(($# == 0)) || {
  printf 'error: this tool takes no positional arguments\n' >&2
  exit 1
}
if ! [[ "$length" =~ ^[0-9]+$ ]] || ((length < 4 || length > 256)); then
  printf 'error: LENGTH must be from 4 to 256\n' >&2
  exit 1
fi
[[ "$count" =~ ^[1-9][0-9]*$ ]] || {
  printf 'error: COUNT must be a positive number\n' >&2
  exit 1
}

ready=0
for tool in tr head; do
  if command -v "$tool" > /dev/null 2>&1; then
    ready=$((ready + 1))
  fi
done
((ready == 2)) || {
  printf 'error: tr and head are needed. Install coreutils.\n' >&2
  exit 1
}

printf '🔐 Making %d password(s) of %d characters\n' "$count" "$length" >&2

i=0
while ((i < count)); do
  # head stops the reader early, so tr gets SIGPIPE. That is expected here.
  set +o pipefail
  LC_ALL=C tr -dc "$chars" < /dev/urandom | head -c "$length"
  set -o pipefail
  printf '\n'
  i=$((i + 1))
done
