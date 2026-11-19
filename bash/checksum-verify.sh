#!/usr/bin/env bash
# Create or check a SHA-256 checksum manifest.
# Usage: checksum-verify.sh -g FILE... | -c MANIFEST
# Needs: sha256sum (Linux) or shasum (macOS)
# Note: manifest paths are relative to the directory you run the check in.

set -euo pipefail

mode=""
manifest=""
files=()

usage() {
  cat << 'EOF'
Make or check a SHA-256 checksum manifest.
Usage: checksum-verify.sh -g FILE... | -c MANIFEST

  -g, --generate FILE...  write a manifest for these files
  -c, --check MANIFEST    check every file listed in this manifest
  -h, --help              show this help

Send the manifest to stdout and redirect it to a file.
EOF
}

while (($# > 0)); do
  case "$1" in
    -g | --generate) mode="gen" ;;
    -c | --check)
      (($# >= 2)) || {
        printf 'error: %s needs a manifest\n' "$1" >&2
        exit 1
      }
      mode="check"
      manifest="$2"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      printf 'error: unknown option %s\n' "$1" >&2
      exit 1
      ;;
    *) files+=("$1") ;;
  esac
  shift
done

if command -v sha256sum > /dev/null 2>&1; then
  tool="sha256sum"
elif command -v shasum > /dev/null 2>&1; then
  tool="shasum"
else
  printf 'error: no SHA-256 tool found. Install coreutils, or use the shasum that ships with macOS.\n' >&2
  exit 1
fi

if [[ "$mode" == "gen" ]]; then
  ((${#files[@]} > 0)) || {
    printf 'error: give at least one file to hash\n' >&2
    exit 1
  }
  for f in "${files[@]}"; do
    [[ -f "$f" ]] || {
      printf 'error: %s is not a file\n' "$f" >&2
      exit 1
    }
  done
  if [[ "$tool" == "sha256sum" ]]; then
    sha256sum "${files[@]}"
  else
    shasum -a 256 "${files[@]}"
  fi
elif [[ "$mode" == "check" ]]; then
  [[ -f "$manifest" ]] || {
    printf 'error: cannot read %s\n' "$manifest" >&2
    exit 1
  }
  printf '🔍 Checking files listed in %s ...\n' "$manifest" >&2
  if [[ "$tool" == "sha256sum" ]]; then
    sha256sum -c "$manifest"
  else
    shasum -a 256 -c "$manifest"
  fi
else
  printf 'error: choose -g or -c\n' >&2
  usage >&2
  exit 1
fi
