#!/usr/bin/env bash
set -euo pipefail

# Sends a desktop notification from the terminal.
# Usage: notify [-t TITLE] [-s SUBTITLE] [-u|--urgent] MESSAGE [-h]
# Needs: osascript
# Note: allow notifications for Script Editor when macOS asks.

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat << 'EOF'
notify - send a macOS desktop notification.

Usage: notify [options] MESSAGE

  -t, --title TITLE     Notification title. Default: Terminal.
  -s, --subtitle TEXT   Second line of text.
  -u, --urgent          Play a sound.
  -h, --help            Show this help.

Example:
  notify -t "Build" "All tests passed."
EOF
}

title="Terminal"
subtitle=""
sound=0
message=""

escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t | --title)
      [[ $# -ge 2 ]] || {
        printf 'Error: %s needs a value.\n' "$1" >&2
        exit 1
      }
      title=$2
      shift 2
      ;;
    -s | --subtitle)
      [[ $# -ge 2 ]] || {
        printf 'Error: %s needs a value.\n' "$1" >&2
        exit 1
      }
      subtitle=$2
      shift 2
      ;;
    -u | --urgent)
      sound=1
      shift
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
      [[ -z "$message" ]] || {
        printf 'Error: give one message only.\n' >&2
        exit 1
      }
      message=$1
      shift
      ;;
  esac
done

if [[ -z "$message" ]]; then
  printf 'Error: a message is required.\n' >&2
  show_help >&2
  exit 1
fi

script="display notification \"$(escape "$message")\""
script="$script with title \"$(escape "$title")\""
if [[ -n "$subtitle" ]]; then
  script="$script subtitle \"$(escape "$subtitle")\""
fi
if [[ $sound -eq 1 ]]; then
  script="$script sound name \"Basso\""
fi

osascript -e "$script"
printf '🔔 Notification sent.\n'
