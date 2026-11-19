#!/usr/bin/env bash
# List the resources in Terraform state, with an optional filter.
# Usage: tf-state-list [-d DIR] [-f PATTERN] [--count]
# Needs: terraform
set -euo pipefail

usage() {
  cat << 'EOF'
Usage: tf-state-list [-d DIR] [-f PATTERN] [--count]

Print one resource address per line. The filter matches addresses
that contain the pattern, and ignores case.

  -d, --dir DIR   Terraform directory. Default: the current directory.
  -f, --filter P  Show only addresses that contain P.
  --count         Print the number of matches only.
  -h, --help      Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

dir="."
pattern=""
count_only=0
while (($# > 0)); do
  case "$1" in
    -d | --dir | -f | --filter)
      (($# > 1)) || die "$1 needs a value."
      case "$1" in
        -d | --dir) dir="$2" ;;
        -f | --filter) pattern="$2" ;;
      esac
      shift
      ;;
    --count) count_only=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

command -v terraform > /dev/null 2>&1 \
  || die 'terraform is not installed. Install it: https://developer.hashicorp.com/terraform/install'
[[ -d "$dir" ]] || die "Directory not found: $dir"

if ! out=$(terraform -chdir="$dir" state list 2>&1); then
  printf '❌ Terraform could not read the state.\n%s\n' "$out" >&2
  die "Check the backend, then run: terraform -chdir=$dir init"
fi

if [[ -z "$out" ]]; then
  printf 'ℹ️  The state is empty.\n' >&2
  exit 0
fi

if [[ -n "$pattern" ]]; then
  out=$(printf '%s\n' "$out" | grep -i -- "$pattern" || true)
  [[ -n "$out" ]] || {
    printf 'ℹ️  No match for %s.\n' "$pattern" >&2
    exit 0
  }
fi

if ((count_only == 1)); then
  total=$(printf '%s\n' "$out" | wc -l)
  printf '%s\n' "${total//[[:space:]]/}"
else
  printf '%s\n' "$out"
fi
