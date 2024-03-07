#!/usr/bin/env bash
# Run cargo check, clippy and a format check.
# Usage: cargo-check [DIR]
# Needs: cargo (with the clippy and rustfmt components)

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: cargo-check [DIR]

Run three checks in DIR and report every failure at the end.
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
[[ -f "$dir/Cargo.toml" ]] || die "No Cargo.toml in $dir."
command -v cargo >/dev/null 2>&1 ||
  die 'cargo is not installed. Install Rust with https://rustup.rs/'

cd "$dir"

fail=0
run_step() {
  printf '🔍 %s\n' "$1"
  shift
  "$@" || fail=1
  printf '\n'
}

run_step 'cargo check' cargo check
run_step 'cargo clippy' cargo clippy -- -D warnings
run_step 'cargo fmt --check' cargo fmt -- --check

if ((fail != 0)); then
  printf '❌ Some checks failed.\n' >&2
  exit 1
fi
printf '✅ All checks passed.\n'
