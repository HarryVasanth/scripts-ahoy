#!/usr/bin/env bash
set -euo pipefail

# Exports macOS defaults domains to plist files.
# Usage: defaults-backup [--out DIR] [DOMAIN...] [-h]
# Needs: defaults

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat << 'EOF'
defaults-backup - save defaults domains to plist files.

Usage: defaults-backup [--out DIR] [DOMAIN...]

  --out DIR   Folder for the files. Default: defaults-backup-<date>.
  -h, --help  Show this help.

With no domain the tool exports every domain that defaults lists. Restore one
file later with: defaults import DOMAIN FILE
EOF
}

out=""
domains=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      [[ $# -ge 2 ]] || {
        printf 'Error: --out needs a value.\n' >&2
        exit 1
      }
      out=$2
      shift 2
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    -*)
      printf 'Error: unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
    *)
      domains+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$out" ]]; then
  out="defaults-backup-$(date +%Y%m%d-%H%M%S)"
fi

mkdir -p "$out"

if [[ ${#domains[@]} -eq 0 ]]; then
  while IFS= read -r name; do
    name=$(printf '%s' "$name" | sed 's/^ *//; s/ *$//')
    [[ -n "$name" ]] && domains+=("$name")
  done < <(defaults domains | tr ',' '\n')
fi

if [[ ${#domains[@]} -eq 0 ]]; then
  printf 'Error: defaults listed no domains.\n' >&2
  exit 1
fi

saved=0
failed=0
for domain in "${domains[@]}"; do
  if defaults export "$domain" "$out/$domain.plist" 2> /dev/null; then
    saved=$((saved + 1))
  else
    printf '⚠️  Could not export: %s\n' "$domain" >&2
    failed=$((failed + 1))
  fi
done

printf '✅ Saved %s domain(s) to %s\n' "$saved" "$out"
if [[ $failed -gt 0 ]]; then
  printf '⚠️  %s domain(s) failed.\n' "$failed" >&2
fi
