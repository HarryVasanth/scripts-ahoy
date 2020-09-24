#!/usr/bin/env bash
set -euo pipefail

# Shows the Gatekeeper status.
# Usage: gatekeeper-status [-h]
# Needs: spctl

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
gatekeeper-status - show the Gatekeeper status.

Usage: gatekeeper-status

Gatekeeper checks the signature and the notarisation of an app before it runs.
When it is enabled, apps from the App Store and from identified developers
can run.
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h | --help) show_help; exit 0 ;;
    *) printf 'Error: unknown argument: %s\n' "$arg" >&2; show_help >&2; exit 1 ;;
  esac
done

if ! status=$(spctl --status 2>&1); then
  printf 'Error: cannot read the Gatekeeper status.\n%s\n' "$status" >&2
  exit 1
fi

printf '🛡️  Gatekeeper: %s\n' "$status"
if [[ $status == *enabled* ]]; then
  printf '✅ The check is active.\n'
else
  printf '⚠️  Gatekeeper is off. Any app can run without a check.\n'
  printf '   Turn it on: sudo spctl --master-enable\n'
fi
