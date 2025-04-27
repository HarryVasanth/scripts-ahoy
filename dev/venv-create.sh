#!/usr/bin/env bash
# Create a Python virtual environment and print the activate command.
# Usage: venv-create [DIR]
# Needs: python3

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: venv-create [DIR]

Create a virtual environment in DIR. The default is .venv.
An existing directory is never removed. Delete it yourself first.

  -h, --help  Show this help.
EOF
}

die() { printf '❌ %s\n' "$1" >&2; exit 1; }

dir=".venv"
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  -*) die "Unknown option: $1" ;;
  "") ;;
  *) dir="$1"; (($# == 1)) || die 'Pass one directory only.' ;;
esac

command -v python3 >/dev/null 2>&1 ||
  die 'python3 is not installed. Install Python 3 first.'

if [[ -e "$dir" ]]; then
  die "$dir already exists. Remove it, or pass another directory."
fi

printf '🐍 Creating %s\n' "$dir"
python3 -m venv "$dir" || die 'Could not create the environment.'

printf '✅ Done\n'
printf '👉 Activate it: source %s/bin/activate\n' "$dir"
