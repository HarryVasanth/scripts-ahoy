#!/usr/bin/env bash

# Find subdomains for a domain in public certificate logs.
# Certificate transparency is free, so this needs no API key. If crt.sh is busy, the script tries Cert Spotter and then HackerTarget.
# Usage: ./subdomain-enum.sh example.com [-o FILE] [-t SECONDS] [--no-fallback] [--wildcards]
# Needs: curl, jq (jq is skipped when the fallback APIs are enough)

set -euo pipefail

DOMAIN=""
OUTPUT=""
TIMEOUT=20
FALLBACK=1
KEEP_WILDCARDS=0
USER_AGENT="scripts-ahoy/subdomain-enum/1.0"

TMP_CRT=""
TMP_CERTSPOTTER=""
TMP_HOSTSEARCH=""

usage() {
  cat <<'EOF'
Usage: subdomain-enum.sh <domain> [options]

Find subdomains for a domain in public certificate logs.

Options:
  -o, --output FILE   Write results to FILE instead of stdout.
  -t, --timeout SECS  Maximum time for each HTTP request. Default: 20.
      --no-fallback   Use crt.sh only. Do not call the backup APIs.
      --wildcards     Keep wildcard names such as *.example.com.
  -h, --help          Show this help.

Examples:
  ./subdomain-enum.sh example.com
  ./subdomain-enum.sh example.com -o subs.txt
  ./subdomain-enum.sh example.com --wildcards --timeout 30

Exit codes:
  0  At least one subdomain was found.
  1  No subdomains were found, or every source failed.
  2  Bad usage.
EOF
}

log() {
  printf '🔎 %s\n' "$*" >&2
}

warn() {
  printf '⚠️  %s\n' "$*" >&2
}

die() {
  printf '❌ %s\n' "$*" >&2
  exit "${2:-1}"
}

have() {
  command -v "$1" >/dev/null 2>&1
}

cleanup() {
  rm -f "$TMP_CRT" "$TMP_CERTSPOTTER" "$TMP_HOSTSEARCH"
}

# Print the bare domain, or fail with a clear message.
normalise_domain() {
  local raw="$1"

  raw="${raw#http://}"
  raw="${raw#https://}"
  raw="${raw%%/*}"
  raw="${raw%%:*}"
  raw="${raw%.}"
  raw=$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')

  if [[ ! $raw =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+$ ]]; then
    die "That does not look like a domain: $1" 2
  fi

  printf '%s' "$raw"
}

# Print one clean name per line. Read from stdin.
normalise_names() {
  local domain="$1"
  local keep_wildcards="$2"

  tr '[:upper:]' '[:lower:]' |
    tr -d '\r' |
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//' |
    awk -v d="$domain" -v keep="$keep_wildcards" '
      {
        name = $0
        wild = 0
        if (substr(name, 1, 2) == "*.") {
          wild = 1
          name = substr(name, 3)
        }
        if (name !~ /^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$/) next
        if (name != d && !(length(name) > length(d) + 1 && substr(name, length(name) - length(d)) == "." d)) next
        if (wild && keep == 1) print "*." name
        else print name
      }
    ' |
    sort -u
}

# Fetch a URL to a file with a few polite retries.
fetch_to_file() {
  local url="$1"
  local out="$2"
  local attempt=1

  while ((attempt <= 3)); do
    if curl -fsS --max-time "$TIMEOUT" -A "$USER_AGENT" -o "$out" "$url"; then
      return 0
    fi
    if ((attempt < 3)); then
      warn "Request failed. Retrying in $((attempt * 2)) seconds..."
      sleep $((attempt * 2))
    fi
    attempt=$((attempt + 1))
  done

  return 1
}

from_crtsh() {
  local url="https://crt.sh/?q=%25.${DOMAIN}&output=json"

  if ! have jq; then
    warn "jq is missing, so crt.sh cannot be parsed."
    return 1
  fi

  log "Asking crt.sh..."
  if ! fetch_to_file "$url" "$TMP_CRT"; then
    return 1
  fi

  if ! jq -e 'type == "array"' "$TMP_CRT" >/dev/null 2>&1; then
    return 1
  fi

  jq -r '.[].name_value // empty' "$TMP_CRT" 2>/dev/null
}

from_certspotter() {
  local url="https://api.certspotter.com/v1/issuances?domain=${DOMAIN}&include_subdomains=true&expand=dns_names"

  if ! have jq; then
    return 1
  fi

  log "Asking Cert Spotter..."
  if ! fetch_to_file "$url" "$TMP_CERTSPOTTER"; then
    return 1
  fi

  if ! jq -e 'type == "array"' "$TMP_CERTSPOTTER" >/dev/null 2>&1; then
    return 1
  fi

  jq -r '.[].dns_names[]? // empty' "$TMP_CERTSPOTTER" 2>/dev/null
}

from_hackertarget() {
  local url="https://api.hackertarget.com/hostsearch/?q=${DOMAIN}"

  log "Asking HackerTarget..."
  if ! fetch_to_file "$url" "$TMP_HOSTSEARCH"; then
    return 1
  fi

  if grep -qiE '^error|API count exceeded|No records' "$TMP_HOSTSEARCH"; then
    return 1
  fi

  cut -d',' -f1 <"$TMP_HOSTSEARCH"
}

# Try each source in order. Print the names from the first source that works.
collect() {
  local source_name=""
  local raw=""

  if raw=$(from_crtsh) && [[ -n $raw ]]; then
    source_name="crt.sh"
  elif [[ $FALLBACK -eq 1 ]] && raw=$(from_certspotter) && [[ -n $raw ]]; then
    source_name="Cert Spotter"
  elif [[ $FALLBACK -eq 1 ]] && raw=$(from_hackertarget) && [[ -n $raw ]]; then
    source_name="HackerTarget"
  else
    return 1
  fi

  log "Using ${source_name}."
  printf '%s\n' "$raw" | normalise_names "$DOMAIN" "$KEEP_WILDCARDS"
}

parse_args() {
  while (($# > 0)); do
    case "$1" in
      -h | --help)
        usage
        exit 0
        ;;
      -o | --output)
        [[ $# -ge 2 && -n $2 ]] || die "Missing value for $1" 2
        OUTPUT="$2"
        shift 2
        ;;
      -t | --timeout)
        [[ $# -ge 2 ]] || die "Missing value for $1" 2
        [[ $2 =~ ^[1-9][0-9]*$ ]] || die "Timeout must be a positive whole number of seconds." 2
        TIMEOUT="$2"
        shift 2
        ;;
      --no-fallback)
        FALLBACK=0
        shift
        ;;
      --wildcards)
        KEEP_WILDCARDS=1
        shift
        ;;
      -*)
        die "Unknown option: $1. Try --help." 2
        ;;
      *)
        [[ -z $DOMAIN ]] || die "Give one domain only." 2
        DOMAIN="$1"
        shift
        ;;
    esac
  done

  [[ -n $DOMAIN ]] || {
    usage >&2
    exit 2
  }
}

main() {
  parse_args "$@"
  DOMAIN=$(normalise_domain "$DOMAIN")

  have curl || die "curl is missing. Install it first."

  TMP_CRT=$(mktemp "${TMPDIR:-/tmp}/subenum-crt.XXXXXX")
  TMP_CERTSPOTTER=$(mktemp "${TMPDIR:-/tmp}/subenum-cs.XXXXXX")
  TMP_HOSTSEARCH=$(mktemp "${TMPDIR:-/tmp}/subenum-ht.XXXXXX")
  trap cleanup EXIT

  log "Looking for subdomains of ${DOMAIN}..."

  local results=""
  if ! results=$(collect); then
    warn "Every source failed. crt.sh may be overloaded. Try again later."
    exit 1
  fi

  local count
  count=$(printf '%s\n' "$results" | awk 'NF { n++ } END { print n + 0 }')

  if ((count == 0)); then
    warn "No subdomains found for ${DOMAIN}."
    exit 1
  fi

  if [[ -n $OUTPUT ]]; then
    out_dir=$(dirname "$OUTPUT")
    [[ -d $out_dir ]] || die "Output directory does not exist: $out_dir"
    [[ -w $out_dir ]] || die "Output directory is not writable: $out_dir"
    if [[ -e $OUTPUT && ! -w $OUTPUT ]]; then
      die "Output file is not writable: $OUTPUT"
    fi
    printf '%s\n' "$results" >"$OUTPUT" || die "Could not write to ${OUTPUT}."
    log "Saved ${count} names to ${OUTPUT}."
  else
    printf '%s\n' "$results"
  fi

  log "Done. Found ${count} unique names. ✨"
}

main "$@"
