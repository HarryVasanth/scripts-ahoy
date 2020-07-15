#!/usr/bin/env bash
set -euo pipefail

# Shows the System Integrity Protection status.
# Usage: sip-status [-h]
# Needs: csrutil

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
sip-status - show the System Integrity Protection status.

Usage: sip-status

SIP protects system files and folders from changes, even by root. Change the
setting only from the macOS Recovery environment.
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h | --help) show_help; exit 0 ;;
    *) printf 'Error: unknown argument: %s\n' "$arg" >&2; show_help >&2; exit 1 ;;
  esac
done

if ! command -v csrutil >/dev/null 2>&1; then
  printf 'Error: csrutil is not available on this Mac.\n' >&2
  exit 1
fi

if ! status=$(csrutil status 2>&1); then
  printf 'Error: cannot read the SIP status.\n%s\n' "$status" >&2
  exit 1
fi

printf '🛡️  System Integrity Protection\n'
printf '%s\n' "$status"
if [[ $status == *enabled* ]]; then
  printf '✅ SIP is active.\n'
else
  printf '⚠️  SIP is off. System files are open to change.\n'
fi
