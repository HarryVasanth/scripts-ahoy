#!/usr/bin/env bash
# Open an interactive shell in a running container.
# Usage: docker-shell [--shell CMD] <container>
# Needs: docker

set -euo pipefail

usage() {
  cat << 'EOF'
Usage: docker-shell [--shell CMD] <container>

Open bash when the image has it. Fall back to sh when it does not.
The container must be running.

  --shell CMD  Use CMD as the shell.
  -h, --help   Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

shell=""
container=""
while (($# > 0)); do
  case "$1" in
    --shell)
      shift
      (($# > 0)) || die 'Option --shell needs a command.'
      shell="$1"
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "Unknown option: $1" ;;
    *)
      [[ -z "$container" ]] || die 'Pass one container only.'
      container="$1"
      ;;
  esac
  shift
done

[[ -n "$container" ]] || {
  usage >&2
  die 'Pass a container name.'
}
command -v docker > /dev/null 2>&1 \
  || die 'docker is not installed. See https://docs.docker.com/get-docker/'
[[ -t 0 ]] || die 'Run this from an interactive terminal.'

running=$(docker inspect -f '{{.State.Running}}' "$container" 2> /dev/null) \
  || die "No container named $container."

if [[ "$running" != "true" ]]; then
  die "$container is not running. Start it with: docker start $container"
fi

if [[ -n "$shell" ]]; then
  exec docker exec -it "$container" "$shell"
fi

shell="sh"
if docker exec "$container" bash -c 'exit 0' > /dev/null 2>&1; then
  shell="bash"
fi

printf '👉 Opening %s in %s\n' "$shell" "$container" >&2
exec docker exec -it "$container" "$shell"
