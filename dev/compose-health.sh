#!/usr/bin/env bash
# Wait until every Docker Compose service is running or healthy.
# Usage: compose-health [-f FILE] [-t SECONDS]
# Needs: docker, Docker Compose (plugin or docker-compose)
set -euo pipefail

usage() {
  cat << 'EOF'
Usage: compose-health [-f FILE] [-t SECONDS]

Poll the services in a Compose project until all of them are up.

  -f, --file FILE   Compose file. Default: the file Compose finds.
  -t, --timeout N   Give up after N seconds. Default: 90.
  -h, --help        Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

file=""
timeout=90
while (($# > 0)); do
  case "$1" in
    -f | --file | -t | --timeout)
      (($# > 1)) || die "$1 needs a value."
      case "$1" in
        -f | --file) file="$2" ;;
        -t | --timeout) timeout="$2" ;;
      esac
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

if [[ ! "$timeout" =~ ^[0-9]+$ ]] || ((timeout == 0)); then die 'The timeout must be a positive number.'; fi

command -v docker > /dev/null 2>&1 || die 'docker is not installed. Install Docker Desktop or docker-ce.'
docker info > /dev/null 2>&1 || die 'Docker is not running. Start Docker Desktop or the docker service.'
if docker compose version > /dev/null 2>&1; then
  compose=(docker compose)
elif command -v docker-compose > /dev/null 2>&1; then
  compose=(docker-compose)
else
  die 'Docker Compose is not installed. Install Docker Desktop or the compose plugin.'
fi
[[ -z "$file" || -f "$file" ]] || die "Compose file not found: $file"
file_args=()
[[ -z "$file" ]] || file_args=(-f "$file")
start=$SECONDS
last=""
while :; do
  out=$("${compose[@]}" "${file_args[@]}" ps --format '{{.Name}} {{.State}} {{.Health}}' 2> /dev/null) || out=""
  all_ok=1
  failed=""
  while read -r name state health; do
    if [[ -n "$name" ]]; then
      state=$(printf '%s' "$state" | tr '[:upper:]' '[:lower:]')
      health=$(printf '%s' "$health" | tr '[:upper:]' '[:lower:]')
      if [[ "$state" != running ]] || { [[ -n "$health" ]] && [[ "$health" != healthy ]]; }; then
        all_ok=0
        [[ "$state" != exited && "$state" != dead ]] || failed="$name"
      fi
    fi
  done <<< "$out"
  if [[ -z "$out" ]]; then all_ok=0; fi
  if [[ -n "$out" && "$out" != "$last" ]]; then
    printf '📋 Current state:\n%s\n' "$out" >&2
    last="$out"
  fi
  [[ -z "$failed" ]] || die "Service $failed is not running. Check the logs."
  ((all_ok == 1)) && {
    printf '✅ All services are up after %ds.\n' "$((SECONDS - start))"
    exit 0
  }
  if ((SECONDS - start >= timeout)); then
    printf '⏰ Timed out after %ds.\n%s\n' "$timeout" "$out" >&2
    exit 1
  fi
  sleep 3
done
