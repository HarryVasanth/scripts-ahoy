#!/usr/bin/env bash
# Write a starter .gitignore for the detected stack.
# Usage: gitignore-init [--force] [DIR]

set -euo pipefail

usage() {
  cat << 'EOF'
Usage: gitignore-init [--force] [DIR]

Detect the project type in DIR and write a starter .gitignore.
The default directory is the current one.

  --force     Overwrite an existing .gitignore.
  -h, --help  Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

force=0
dir="."
while (($# > 0)); do
  case "$1" in
    --force) force=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "Unknown option: $1" ;;
    *) dir="$1" ;;
  esac
  shift
done

[[ -d "$dir" ]] || die "Directory not found: $dir"
target="$dir/.gitignore"
if [[ -e "$target" ]] && ((force == 0)); then
  die "$target exists. Use --force to overwrite it."
fi

tmp=$(mktemp "$dir/.gitignore.XXXXXX")
trap 'rm -f "$tmp"' EXIT
stacks=""
add() {
  stacks="$stacks $1"
  printf '\n# %s\n%b' "$1" "$2"
}

{
  printf '# OS files\n.DS_Store\nThumbs.db\n\n# Logs and local settings\n*.log\n.env\n'
  if [[ -f "$dir/package.json" ]]; then add Node 'node_modules/\nnpm-debug.log*\nyarn-error.log\n'; fi
  if [[ -f "$dir/go.mod" ]]; then add Go '*.exe\n*.test\n'; fi
  if [[ -f "$dir/Cargo.toml" ]]; then add Rust 'target/\n'; fi
  if [[ -f "$dir/pyproject.toml" || -f "$dir/requirements.txt" || -f "$dir/setup.py" ]]; then
    add Python '__pycache__/\n*.pyc\n.venv/\n'
  fi
  if [[ -f "$dir/Gemfile" ]]; then add Ruby '.bundle/\nvendor/bundle/\n'; fi
  if [[ -f "$dir/composer.json" ]]; then add PHP 'vendor/\n'; fi
  if compgen -G "$dir/*.tf" > /dev/null; then add Terraform '.terraform/\n*.tfstate\n*.tfstate.backup\n'; fi
  if [[ -f "$dir/Dockerfile" ]]; then stacks="$stacks Docker"; fi
} > "$tmp"

mv "$tmp" "$target"
trap - EXIT
printf '✅ Wrote %s\n' "$target" >&2
if [[ -n "$stacks" ]]; then
  printf '👉 Detected:%s\n' "$stacks" >&2
else
  printf 'ℹ️  No known stack detected. The shared entries still apply.\n' >&2
fi
