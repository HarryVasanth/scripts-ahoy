#!/usr/bin/env bash
# Ask a yes/no question and return the answer as an exit code.
# Usage: ask.sh [-y|-n] PROMPT...

set -euo pipefail

default=""

usage() {
  cat <<'EOF'
Ask a yes/no question.
Usage: ask.sh [-y|-n] PROMPT...

  -y, --yes     use yes as the default answer
  -n, --no      use no as the default answer
  -h, --help    show this help

Exit code 0 means yes. Exit code 1 means no.
EOF
}

while (($# > 0)); do
  case "$1" in
    -y|--yes) default="y"; shift ;;
    -n|--no) default="n"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
done

(($# > 0)) || { printf 'error: give a question to ask\n' >&2; usage >&2; exit 1; }
question="$*"

hint="[y/n]"
case "$default" in
  y) hint="[Y/n]" ;;
  n) hint="[y/N]" ;;
esac

while :; do
  printf '❓ %s %s ' "$question" "$hint"
  if ! read -r answer; then
    printf '\n'
    if [[ -z "$default" ]]; then
      printf 'error: no answer and no default\n' >&2
      exit 1
    fi
    answer="$default"
  fi
  answer=$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')
  if [[ -z "$answer" ]]; then
    answer="$default"
  fi
  case "$answer" in
    y|yes) printf '✅ Yes\n'; exit 0 ;;
    n|no) printf '❌ No\n'; exit 1 ;;
    *) printf 'Please answer y or n.\n' >&2 ;;
  esac
done
