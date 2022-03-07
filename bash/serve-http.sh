#!/usr/bin/env bash
# Serve a directory over HTTP with the Python standard library.
# Usage: serve-http.sh [-p PORT] [-b ADDRESS] [DIR]
# Needs: python3
# Note: the default address is localhost. Use -b 0.0.0.0 to share on the network.

set -euo pipefail

port=8000
bind="127.0.0.1"
dir="."

usage() {
  cat <<'EOF'
Serve files from a directory over HTTP.
Usage: serve-http.sh [-p PORT] [-b ADDRESS] [DIR]

  -p PORT      port to listen on (default: 8000)
  -b ADDRESS   address to bind (default: 127.0.0.1)
  -h, --help   show this help

Press Ctrl+C to stop the server.
EOF
}

while (($# > 0)); do
  case "$1" in
    -p|--port)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      port="$2"; shift ;;
    -b|--bind)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      bind="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
  shift
done

(($# <= 1)) || { printf 'error: give one directory only\n' >&2; exit 1; }
if (($# == 1)); then
  dir="$1"
fi
[[ -d "$dir" ]] || { printf 'error: %s is not a directory\n' "$dir" >&2; exit 1; }
if ! [[ "$port" =~ ^[0-9]+$ ]] || ((port < 1 || port > 65535)); then
  printf 'error: PORT must be a number from 1 to 65535\n' >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  printf 'error: python3 is needed. Install it with: brew install python (macOS) or apt install python3 (Debian/Ubuntu).\n' >&2
  exit 1
fi

shown="$bind"
if [[ "$bind" == "0.0.0.0" ]]; then
  shown="localhost"
fi
printf '🌐 Serving %s at http://%s:%s/\n' "$dir" "$shown" "$port" >&2

exec python3 -m http.server "$port" --bind "$bind" --directory "$dir"
