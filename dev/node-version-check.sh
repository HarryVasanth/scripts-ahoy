#!/usr/bin/env bash
# Check that the local Node.js version matches the project requirement.
# Usage: node-version-check [--min VERSION] [directory]
# Needs: node, jq (jq only reads package.json engines)
set -euo pipefail

usage() {
  cat << 'EOF'
Usage: node-version-check [--min VERSION] [directory]

Read the required Node version from --min, .nvmrc or package.json
engines.node, then compare it with the local Node version.

  --min VERSION  Use this minimum version instead of a project file.
  -h, --help     Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

ge() {
  local i
  local -a a b
  IFS=. read -r -a a <<< "$1"
  IFS=. read -r -a b <<< "$2"
  for i in 0 1 2; do
    if ((10#${a[i]:-0} != 10#${b[i]:-0})); then
      ((10#${a[i]:-0} > 10#${b[i]:-0}))
      return
    fi
  done
  return 0
}

min=""
dir="."
while (($# > 0)); do
  case "$1" in
    --min)
      (($# > 1)) || die '--min needs a version.'
      min="$2"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "Unknown option: $1" ;;
    *) dir="$1" ;;
  esac
  shift
done

command -v node > /dev/null 2>&1 \
  || die 'node is not installed. Install it from https://nodejs.org or with nvm: nvm install --lts'
[[ -d "$dir" ]] || die "Directory not found: $dir"
current=$(node --version)
current=${current#v}
raw=""
source=""
if [[ -n "$min" ]]; then
  raw="$min"
  source="--min"
elif [[ -f "$dir/.nvmrc" ]]; then
  raw=$(head -n 1 "$dir/.nvmrc")
  source=".nvmrc"
elif [[ -f "$dir/package.json" ]]; then
  if command -v jq > /dev/null 2>&1; then
    raw=$(jq -r '.engines.node // empty' "$dir/package.json")
  else
    raw=$(sed -n 's/.*"node"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$dir/package.json" | head -n 1)
  fi
  source="package.json engines.node"
fi
required=$(printf '%s' "$raw" | sed -e 's/^[^0-9]*//' -e 's/[^0-9.].*$//' -e 's/\.$//')
if [[ -z "$required" && -n "$raw" ]]; then die "Cannot read a version number from $source: $raw"; fi
if [[ -z "$required" ]]; then
  printf 'ℹ️  No version requirement found for %s.\n' "$dir" >&2
  printf '💻 Local Node is v%s.\n' "$current"
  exit 0
fi
msg="Need Node $required (from $source). You have v$current."
if ge "$current" "$required"; then
  printf '🔎 %s\n✅ Version is new enough.\n' "$msg"
  exit 0
fi
die "$msg Node is too old. Run: nvm install $required && nvm use $required"
