#!/usr/bin/env bash
# Follow logs for a container or a Docker Compose service.
# Usage: docker-logs [--tail N] <name>
# Needs: docker, docker-compose (only for compose services)

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: docker-logs [--tail N] <name>

Follow the logs of a running container. If the name is a service in a
compose file in the current directory, use that project instead.

  --tail N    Start with the last N lines. The default is 200.
  -h, --help  Show this help.
EOF
}

die() { printf '❌ %s\n' "$1" >&2; exit 1; }

tail="200"
name=""
while (($# > 0)); do
  case "$1" in
    --tail) shift; (($# > 0)) || die 'Option --tail needs a count.'; tail="$1" ;;
    -h|--help) usage; exit 0 ;;
    -*) die "Unknown option: $1" ;;
    *)
      [[ -z "$name" ]] || die 'Pass one name only.'
      name="$1"
      ;;
  esac
  shift
done

[[ -n "$name" ]] || { usage >&2; die 'Pass a container or service name.'; }
case "$tail" in
  ''|*[!0-9]*) die "The tail count must be a number: $tail" ;;
esac
command -v docker >/dev/null 2>&1 ||
  die 'docker is not installed. See https://docs.docker.com/get-docker/'

compose=""
for candidate in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
  if [[ -f "$candidate" ]]; then
    compose="$candidate"
    break
  fi
done

if [[ -n "$compose" ]] && command -v docker-compose >/dev/null 2>&1; then
  if docker-compose -f "$compose" config --services 2>/dev/null | grep -Fxq "$name"; then
    printf '📜 Following service %s in %s\n' "$name" "$compose" >&2
    exec docker-compose -f "$compose" logs -f --tail "$tail" "$name"
  fi
fi

docker inspect "$name" >/dev/null 2>&1 ||
  die "No container or compose service named $name."

printf '📜 Following container %s\n' "$name" >&2
exec docker logs -f --tail "$tail" "$name"
