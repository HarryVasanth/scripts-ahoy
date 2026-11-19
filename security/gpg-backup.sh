#!/usr/bin/env bash
# Back up GnuPG public keys and trust settings.
# Usage: gpg-backup.sh [-o DIR] [-u KEYID] [-f] [-h]
# Needs: gpg
# Note: It saves public data only. Keep your secret keys offline.

set -euo pipefail

OUT="gpg-backup-$(date +%Y%m%d)"
KEY=
FORCE=0

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

command -v gpg > /dev/null 2>&1 || die "gpg is not installed. Try: brew install gnupg or apt install gnupg"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -o)
      [ "$#" -ge 2 ] || die "-o needs a path."
      OUT=$2
      shift 2
      ;;
    -u)
      [ "$#" -ge 2 ] || die "-u needs a key ID."
      KEY=$2
      shift 2
      ;;
    -f | --force)
      FORCE=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "unknown option $1" ;;
  esac
done

if [ -e "$OUT" ] && [ "$FORCE" -eq 0 ]; then
  die "$OUT exists. Use -f to overwrite."
fi
mkdir -p "$OUT"

TMP1=$(mktemp "${OUT}/.public.XXXXXX")
TMP2=$(mktemp "${OUT}/.trust.XXXXXX")
trap 'rm -f "${TMP1:-}" "${TMP2:-}"' EXIT

if [ -n "$KEY" ]; then
  gpg --batch --armor --export "$KEY" > "$TMP1" || die "export failed for $KEY"
else
  gpg --batch --armor --export > "$TMP1" || die "export failed"
fi
[ -s "$TMP1" ] || die "no public keys found in the keyring."
gpg --batch --export-ownertrust > "$TMP2" 2> /dev/null || true

mv "$TMP1" "$OUT/public-keys.asc"
mv "$TMP2" "$OUT/ownertrust.txt"
COUNT=$(grep -c 'BEGIN PGP PUBLIC KEY BLOCK' "$OUT/public-keys.asc" || true)

printf '✅ Saved %s public key(s) to %s\n' "${COUNT:-0}" "$OUT/public-keys.asc"
printf '   Trust settings: %s/ownertrust.txt\n' "$OUT"
printf '   To restore: gpg --import %s/public-keys.asc\n' "$OUT"
