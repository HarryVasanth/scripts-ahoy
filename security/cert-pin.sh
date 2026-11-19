#!/usr/bin/env bash
# Show the SHA-256 public key pin for a TLS certificate.
# Usage: cert-pin.sh [-p PORT] [-s NAME] HOST
# Needs: openssl
# Note: The pin breaks when the server rotates its key.

set -euo pipefail

PORT=443
NAME=

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -p)
      [ "$#" -ge 2 ] || die "-p needs a port."
      PORT=$2
      shift 2
      ;;
    -s)
      [ "$#" -ge 2 ] || die "-s needs a name."
      NAME=$2
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

case "$PORT" in
  '' | *[!0-9]*) die "the port must be a number." ;;
esac
[ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ] || die "the port must be 1 to 65535."

command -v openssl > /dev/null 2>&1 || die "openssl is not installed."
[ "$#" -eq 1 ] || die "give one host name."
HOST=$1
[ -n "$NAME" ] || NAME=$HOST

TMP=$(mktemp "${TMPDIR:-/tmp}/cert-pin.XXXXXX")
trap 'rm -f "$TMP"' EXIT

openssl s_client -connect "$HOST:$PORT" -servername "$NAME" -showcerts < /dev/null > "$TMP" 2> /dev/null \
  || die "TLS handshake with $HOST:$PORT failed."

SUBJECT=$(openssl x509 -in "$TMP" -noout -subject 2> /dev/null || true)
ISSUER=$(openssl x509 -in "$TMP" -noout -issuer 2> /dev/null || true)
DATES=$(openssl x509 -in "$TMP" -noout -dates 2> /dev/null || true)
PIN=$(openssl x509 -in "$TMP" -pubkey -noout 2> /dev/null \
  | openssl pkey -pubin -outform der 2> /dev/null \
  | openssl dgst -sha256 -binary 2> /dev/null \
  | openssl enc -base64 2> /dev/null || true)
[ -n "$PIN" ] || die "cannot read the certificate."

printf '🌐 %s:%s (%s)\n' "$HOST" "$PORT" "$NAME"
printf '   %s\n' "${SUBJECT:-subject unknown}"
printf '   %s\n' "${ISSUER:-issuer unknown}"
printf '   %s\n' "$(printf '%s' "$DATES" | tr '\n' ' ')"
if ! openssl x509 -in "$TMP" -noout -checkend 0 > /dev/null 2>&1; then
  printf '⚠️  The certificate has expired.\n'
fi
printf '\n🔐 Public key pin (SHA-256)\n   sha256/%s\n' "$PIN"
