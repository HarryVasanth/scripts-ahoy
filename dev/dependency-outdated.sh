#!/usr/bin/env bash
# Show outdated dependencies for the project in a directory.
# Usage: dependency-outdated [--dir DIR]
# Needs: the package manager that the project uses
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: dependency-outdated [--dir DIR]

Find the project type, then run its outdated report:
pnpm, npm, yarn, cargo, go, pip, bundler or composer.

  --dir DIR  Project directory. Default: the current directory.
  -h, --help Show this help.
EOF
}

die() { printf '❌ %s\n' "$1" >&2; exit 1; }

require() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is not installed. $2"
}

dir="."
while (($# > 0)); do
  case "$1" in
    --dir) (($# > 1)) || die '--dir needs a path.'; dir="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

[[ -d "$dir" ]] || die "Directory not found: $dir"
cd "$dir"

if [[ -f pnpm-lock.yaml ]]; then
  require pnpm 'Enable it with: corepack enable'
  pnpm outdated || true
elif [[ -f yarn.lock ]]; then
  require yarn 'Install it from https://yarnpkg.com'
  yarn outdated || true
elif [[ -f package-lock.json || -f package.json ]]; then
  require npm 'Install Node.js from https://nodejs.org'
  npm outdated || true
elif [[ -f Cargo.toml ]]; then
  require cargo 'Install Rust from https://rustup.rs'
  require cargo-outdated 'Install it with: cargo install cargo-outdated'
  cargo outdated || true
elif [[ -f go.mod ]]; then
  require go 'Install Go from https://go.dev/dl/'
  go list -m -u all || true
elif [[ -f requirements.txt || -f pyproject.toml ]]; then
  require python3 'Install Python from https://python.org'
  python3 -m pip --version >/dev/null 2>&1 || die 'pip is not available. Run: python3 -m ensurepip'
  python3 -m pip list --outdated || true
elif [[ -f Gemfile ]]; then
  require bundle 'Install it with: gem install bundler'
  bundle outdated || true
elif [[ -f composer.json ]]; then
  require composer 'Install it from https://getcomposer.org'
  composer outdated || true
else
  die "No supported project here ($dir). Supported: pnpm, npm, yarn, cargo, go, pip, bundler, composer."
fi
