#!/usr/bin/env bash
# Run a command again until it succeeds.
# Usage: retry.sh [-n TRIES] [-d DELAY] [-m MAX] -- COMMAND [ARGS...]

set -euo pipefail

tries=5
delay=2
max=60
status=0

usage() {
  cat <<'EOF'
Run a command until it succeeds, with a growing delay.
Usage: retry.sh [-n TRIES] [-d DELAY] [-m MAX] -- COMMAND [ARGS...]

  -n TRIES      number of attempts (default: 5)
  -d DELAY      first delay in seconds (default: 2)
  -m MAX        largest delay in seconds (default: 60)
  -h, --help    show this help

Example: retry.sh -n 3 -- curl -fsS https://example.com
EOF
}

while (($# > 0)); do
  case "$1" in
    -n|--tries)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      tries="$2"; shift 2 ;;
    -d|--delay)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      delay="$2"; shift 2 ;;
    -m|--max)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      max="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
done

(($# > 0)) || { printf 'error: give a command to run\n' >&2; usage >&2; exit 1; }
for value in "$tries" "$delay" "$max"; do
  [[ "$value" =~ ^[0-9]+$ ]] || { printf 'error: numbers only for -n, -d and -m\n' >&2; exit 1; }
done
((tries > 0)) || { printf 'error: TRIES must be at least 1\n' >&2; exit 1; }

attempt=1
while :; do
  printf '🔁 Attempt %d/%d\n' "$attempt" "$tries" >&2
  status=0
  "$@" || status=$?

  if ((status == 0)); then
    printf '✅ Command succeeded on attempt %d\n' "$attempt" >&2
    exit 0
  fi

  if ((attempt >= tries)); then
    printf '❌ Command failed after %d attempt(s), status %d\n' "$attempt" "$status" >&2
    exit 1
  fi

  printf '⏳ Waiting %d second(s) before the next try\n' "$delay" >&2
  sleep "$delay"
  delay=$((delay * 2))
  if ((delay > max)); then
    delay=$max
  fi
  attempt=$((attempt + 1))
done
