#!/usr/bin/env bash
set -euo pipefail

# Checks cron files for common mistakes.
# Usage: cron-lint [-h]
# Needs: awk, sort, tail
# Note: the tool checks /etc/crontab, /etc/cron.d and the current user crontab.

show_help() {
  cat <<'EOF'
cron-lint - check cron files for common mistakes.

Usage: cron-lint

Checks for CRLF line endings, a missing final newline, commands that are not
absolute paths and duplicate lines. Exit status is 1 when it finds a problem.
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h | --help) show_help; exit 0 ;;
    *) printf 'Error: unknown argument: %s\n' "$arg" >&2; show_help >&2; exit 1 ;;
  esac
done

tmp=""
# shellcheck disable=SC2329  # called by the EXIT trap below
cleanup() { if [[ -n "$tmp" ]]; then rm -f "$tmp"; fi; }
trap cleanup EXIT
problems=0
check_file() {
  local file=$1 offset=$2 label=$3 line
  printf '== %s ==\n' "$label"

  if grep -q $'\r' "$file" 2>/dev/null; then
    printf '  ❌ CRLF line endings. Convert the file to Unix line endings.\n'
    problems=$((problems + 1))
  fi
  if [[ -s "$file" ]] && [[ -n "$(tail -c 1 "$file")" ]]; then
    printf '  ⚠️  No final newline. Some cron versions skip the last line.\n'
    problems=$((problems + 1))
  fi

  while IFS= read -r line; do
    printf '  ❌ %s\n' "$line"
    problems=$((problems + 1))
  done < <(awk -v off="$offset" '
    /^[[:space:]]*(#|$)/ {next}
    /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=/ {next}
    $off != "" && substr($off, 1, 1) != "/" {
      print "line " NR ": command is not an absolute path: " $off
    }' "$file")

  while IFS= read -r line; do
    printf '  ⚠️  Duplicate line: %s\n' "$line"
    problems=$((problems + 1))
  done < <(grep -vE '^[[:space:]]*(#|$)' "$file" | sort | uniq -d || true)
}

for f in /etc/crontab /etc/cron.d/*; do
  if [[ -f "$f" ]]; then
    check_file "$f" 7 "$f"
  fi
done

if command -v crontab >/dev/null 2>&1; then
  tmp=$(mktemp "${TMPDIR:-/tmp}/cron-lint.XXXXXX")
  if crontab -l >"$tmp" 2>/dev/null; then
    check_file "$tmp" 6 "current user crontab"
  fi
fi

if [[ $problems -eq 0 ]]; then
  printf '\n✅ No problems found.\n'
  exit 0
fi

printf '\n❌ %s problem(s) found.\n' "$problems"
exit 1
