#!/usr/bin/env bash
# Create a small, standard project skeleton without overwriting files.
# Usage: project-bootstrap [--dry-run] <directory>
set -euo pipefail

usage() {
  cat << 'EOF'
Usage: project-bootstrap [--dry-run] <directory>

Create src/, test/, docs/, .gitignore and a starter README.
Any file that already exists is kept.

  -n, --dry-run  Show the plan. Change nothing.
  -h, --help     Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

make_dir() {
  [[ -d "$1" ]] && {
    printf '⏭️  Kept %s\n' "$1"
    return
  }
  ((dry_run == 1)) && {
    printf '📁 Would create %s\n' "$1"
    return
  }
  mkdir -p "$1" && printf '📁 Created %s\n' "$1"
}

write_file() {
  [[ -e "$1" ]] && {
    printf '⏭️  Kept %s\n' "$1"
    return
  }
  ((dry_run == 1)) && {
    printf '📝 Would write %s\n' "$1"
    return
  }
  printf '%s\n' "$2" > "$1" && printf '📝 Wrote %s\n' "$1"
}

dry_run=0
target=""
while (($# > 0)); do
  case "$1" in
    -n | --dry-run) dry_run=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "Unknown option: $1" ;;
    *)
      [[ -z "$target" ]] || die 'Pass one directory only.'
      target="$1"
      ;;
  esac
  shift
done

[[ -n "$target" ]] || {
  usage >&2
  die 'A directory is required.'
}
[[ ! -e "$target" || -d "$target" ]] || die "Not a directory: $target"
((dry_run == 1)) || mkdir -p "$target"

make_dir "$target/src"
make_dir "$target/test"
make_dir "$target/docs"
write_file "$target/.gitignore" $'.DS_Store\nnode_modules/\n*.log\n'
write_file "$target/README.md" $'# Project name\n\nOne line about this project.\n'

printf '✅ Skeleton ready in %s\n' "$target" >&2
