#!/usr/bin/env bash
set -euo pipefail

# Locks a macOS keychain at once.
# Usage: lock-keychain [PATH] [-h]
# Needs: security

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
lock-keychain - lock a keychain.

Usage: lock-keychain [PATH]

  PATH        Keychain to lock. Default: the login keychain.
  -h, --help  Show this help.

Apps must ask for the password again after the keychain is locked.
EOF
}

if ! command -v security >/dev/null 2>&1; then
  printf 'Error: the security tool is missing. This tool needs macOS.\n' >&2
  exit 1
fi

keychain=""
for arg in "$@"; do
  case "$arg" in
    -h | --help) show_help; exit 0 ;;
    -*) printf 'Error: unknown argument: %s\n' "$arg" >&2; exit 1 ;;
    *)
      [[ -z "$keychain" ]] || { printf 'Error: give one keychain only.\n' >&2; exit 1; }
      keychain=$arg
      ;;
  esac
done

if [[ -z "$keychain" ]]; then
  keychain=$HOME/Library/Keychains/login.keychain-db
  if [[ ! -f "$keychain" ]]; then
    keychain=$HOME/Library/Keychains/login.keychain
  fi
fi

if [[ ! -f "$keychain" ]]; then
  printf 'Error: the keychain does not exist: %s\n' "$keychain" >&2
  exit 1
fi

security lock-keychain "$keychain"
printf '🔒 Locked: %s\n' "$keychain"
