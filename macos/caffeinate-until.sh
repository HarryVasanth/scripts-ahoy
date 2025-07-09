#!/usr/bin/env bash
set -euo pipefail

# Keeps the Mac awake for a time, or until a command finishes.
# Usage: caffeinate-until [-t SECONDS | -- COMMAND [ARGS...]] [-h]
# Needs: caffeinate
# Note: keep this terminal open. The Mac can sleep after the tool exits.

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
caffeinate-until - keep the Mac awake.

Usage: caffeinate-until --time SECONDS
       caffeinate-until -- COMMAND [ARGS...]

  -t, --time SECONDS   Stay awake for this many seconds.
  -h, --help           Show this help.

With a command, the Mac stays awake only while the command runs.
Example: caffeinate-until -- rsync -a /data /backup
EOF
}

if ! command -v caffeinate >/dev/null 2>&1; then
  printf 'Error: caffeinate is missing. This tool needs macOS.\n' >&2
  exit 1
fi

seconds=""
command_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t | --time)
      [[ $# -ge 2 ]] || { printf 'Error: %s needs a value.\n' "$1" >&2; exit 1; }
      seconds=$2
      shift 2
      ;;
    -h | --help) show_help; exit 0 ;;
    --)
      shift
      command_args=("$@")
      break
      ;;
    *)
      command_args=("$@")
      break
      ;;
  esac
done

if [[ -n "$seconds" && ${#command_args[@]} -gt 0 ]]; then
  printf 'Error: give a time or a command, not both.\n' >&2
  exit 1
fi

if [[ -n "$seconds" ]]; then
  if [[ ! $seconds =~ ^[0-9]+$ ]] || [[ $seconds -lt 1 ]]; then
    printf 'Error: the time must be a positive number of seconds.\n' >&2
    exit 1
  fi
  printf '☕ Staying awake for %s seconds.\n' "$seconds"
  caffeinate -dims -t "$seconds"
  printf '✅ The session is over.\n'
  exit 0
fi

if [[ ${#command_args[@]} -eq 0 ]]; then
  printf 'Error: give a time or a command.\n' >&2
  show_help >&2
  exit 1
fi

printf '☕ Staying awake until the command exits.\n'
caffeinate -dims -- "${command_args[@]}"
