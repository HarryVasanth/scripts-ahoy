#!/usr/bin/env bash
# Pull images for a Docker Compose project.
# Usage: compose-pull [-f FILE] [SERVICE...]
# Needs: docker-compose

set -euo pipefail

usage() {
  cat << 'EOF'
Usage: compose-pull [-f FILE] [SERVICE...]

Pull the newest images for every service, or for the named services.
The compose file is found in the current directory when -f is omitted.

  -f FILE     Use FILE as the compose file.
  -h, --help  Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

file=""
services=()
while (($# > 0)); do
  case "$1" in
    -f | --file)
      shift
      (($# > 0)) || die 'Option -f needs a file.'
      file="$1"
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "Unknown option: $1" ;;
    *) services+=("$1") ;;
  esac
  shift
done

if [[ -z "$file" ]]; then
  for candidate in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
    if [[ -f "$candidate" ]]; then
      file="$candidate"
      break
    fi
  done
fi
[[ -n "$file" ]] || die 'No compose file found here. Use -f FILE.'
[[ -f "$file" ]] || die "File not found: $file"

command -v docker-compose > /dev/null 2>&1 \
  || die 'docker-compose is not installed. See https://docs.docker.com/compose/install/'

printf '📦 Pulling images for %s\n' "$file"
if ((${#services[@]} == 0)); then
  docker-compose -f "$file" pull || die 'Pull failed. Read the output above.'
else
  docker-compose -f "$file" pull "${services[@]}" \
    || die 'Pull failed. Check the service names.'
fi
printf '✅ Images are up to date.\n'
