#!/usr/bin/env bash
set -euo pipefail
# Waits until a systemd service is active or failed.
# Usage: service-wait [-t SECONDS] UNIT [-h]
# Needs: systemctl (systemd)
show_help() {
  cat << 'EOF'
service-wait - wait for a systemd service to become active.

Usage: service-wait [--timeout SECONDS] UNIT

  -t, --timeout SECONDS   Give up after this time. Default: 60.
  -h, --help              Show this help.

The exit status is 1 on a timeout or a failed unit. This suits start-up
scripts that must run after a service is ready.
EOF
}
if ! command -v systemctl > /dev/null 2>&1; then
  printf 'Error: systemctl is missing. This tool needs systemd.\n' >&2
  exit 1
fi
timeout=60
unit=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t | --timeout)
      [[ $# -ge 2 ]] || {
        printf 'Error: %s needs a value.\n' "$1" >&2
        exit 1
      }
      timeout=$2
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
      [[ -z "$unit" ]] || {
        printf 'Error: give one unit only.\n' >&2
        exit 1
      }
      unit=$1
      shift
      ;;
  esac
done
if [[ -z "$unit" ]]; then
  printf 'Error: a unit name is required.\n' >&2
  show_help >&2
  exit 1
fi
if [[ ! $timeout =~ ^[0-9]+$ ]]; then
  printf 'Error: the timeout must be a number.\n' >&2
  exit 1
fi
waited=0
while :; do
  state=$(systemctl is-active "$unit" 2> /dev/null || true)
  case "$state" in
    active)
      printf '✅ %s is active after %s seconds.\n' "$unit" "$waited"
      exit 0
      ;;
    failed)
      printf '❌ %s failed. Check it with: systemctl status %s\n' "$unit" "$unit" >&2
      exit 1
      ;;
  esac
  if [[ $waited -ge $timeout ]]; then
    printf '❌ Timeout. %s is %s after %s seconds.\n' "$unit" "${state:-unknown}" "$waited" >&2
    exit 1
  fi
  if [[ $waited -gt 0 ]] && [[ $((waited % 5)) -eq 0 ]]; then
    printf '⏳ Still waiting (%s seconds).\n' "$waited" >&2
  fi
  sleep 1
  waited=$((waited + 1))
done
