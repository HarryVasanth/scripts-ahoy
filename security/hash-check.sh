#!/usr/bin/env bash
# Print or verify SHA-256 checksums.
# Usage: hash-check.sh [-c SHA256SUMS] [-h]
# Usage: hash-check.sh FILE... > SHA256SUMS
# Needs: shasum (macOS) or sha256sum (Linux)

set -euo pipefail

if command -v sha256sum > /dev/null 2>&1; then
  TOOL=(sha256sum)
elif command -v shasum > /dev/null 2>&1; then
  TOOL=(shasum -a 256)
else
  printf 'Error: need sha256sum or shasum. On macOS they ship with the system.\n' >&2
  exit 1
fi

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

CHECK=
while [ "$#" -gt 0 ]; do
  case "$1" in
    -c)
      [ "$#" -ge 2 ] || die "-c needs a manifest."
      CHECK=$2
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "unknown option $1" ;;
    *) break ;;
  esac
done

if [ -n "$CHECK" ]; then
  [ -r "$CHECK" ] || die "cannot read $CHECK"
  if "${TOOL[@]}" -c "$CHECK"; then
    printf '✅ All checksums match.\n'
  else
    printf '❌ Checksum check failed.\n' >&2
    exit 1
  fi
  exit 0
fi

[ "$#" -gt 0 ] || die "give at least one file, or use -c MANIFEST."
for f in "$@"; do
  [ -f "$f" ] || die "not a file: $f"
done

"${TOOL[@]}" -- "$@"
