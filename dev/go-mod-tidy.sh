#!/usr/bin/env bash
# Tidy and verify Go module files.
# Usage: go-mod-tidy [DIR]
# Needs: go (modules need Go 1.11 or later)
# Since: 2018-08

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: go-mod-tidy [DIR]

Run "go mod tidy" and then "go mod verify" in DIR.
The default directory is the current one.

  -h, --help  Show this help.
EOF
}

die() { printf '❌ %s\n' "$1" >&2; exit 1; }

dir="."
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  -*) die "Unknown option: $1" ;;
  "") ;;
  *) dir="$1"; (($# == 1)) || die 'Pass one directory only.' ;;
esac

[[ -d "$dir" ]] || die "Directory not found: $dir"
[[ -f "$dir/go.mod" ]] || die "No go.mod in $dir. Run this inside a Go module."
command -v go >/dev/null 2>&1 ||
  die 'go is not installed. Install Go from https://go.dev/dl/'

cd "$dir"

printf '🧹 go mod tidy\n'
go mod tidy || die 'go mod tidy failed. Read the errors above.'

printf '🔎 go mod verify\n'
go mod verify || die 'go mod verify failed.'

printf '✅ Modules are tidy and verified.\n'
