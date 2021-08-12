#!/usr/bin/env bash
# Create a .env.example file from .env with the values removed.
# Usage: env-example [--force] [FILE]

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: env-example [--force] [FILE]

Read FILE and write FILE.example with every value emptied.
Comments and key order stay the same. The default file is .env.

  --force     Overwrite the example file.
  -h, --help  Show this help.
EOF
}

die() { printf '❌ %s\n' "$1" >&2; exit 1; }

force=0
file=".env"
while (($# > 0)); do
  case "$1" in
    --force) force=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) die "Unknown option: $1" ;;
    *) file="$1" ;;
  esac
  shift
done

[[ -f "$file" ]] || die "File not found: $file"
out="$file.example"
if [[ -e "$out" ]] && ((force == 0)); then
  die "$out exists. Use --force to overwrite it."
fi

# Keep the "KEY=" part and drop everything after it.
if ! sed -E 's/^([[:space:]]*(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=).*/\1/' "$file" > "$out"; then
  rm -f "$out"
  die "Could not write $out"
fi

lines=$(wc -l < "$out" | tr -d '[:space:]')
printf '✅ Wrote %s (%s lines)\n' "$out" "$lines" >&2
printf '👉 Review it before you commit. The values are empty.\n' >&2
