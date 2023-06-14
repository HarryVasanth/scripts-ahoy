#!/usr/bin/env bash
# Show Docker disk usage, with an optional clean-up.
# Usage: docker-usage [--prune] [--all] [--volumes] [--dry-run] [--yes]
# Needs: docker
# Note: Volumes are never removed unless you pass --volumes.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: docker-usage [--prune] [--all] [--volumes] [--dry-run] [--yes]

With no flags, print the disk usage and the image list.
With --prune, remove unused data and then show the new usage.

  --prune     Remove stopped containers, dangling images and unused networks.
  --all       With --prune, remove all unused images, not just dangling ones.
  --volumes   With --prune, also remove unused volumes. This deletes data.
  --dry-run   Show what --prune would remove. Change nothing.
  --yes       Skip the confirmation prompt.
  -h, --help  Show this help.
EOF
}

die() { printf '❌ %s\n' "$1" >&2; exit 1; }

prune=0
all=0
volumes=0
dry_run=0
yes=0
while (($# > 0)); do
  case "$1" in
    --prune) prune=1 ;;
    --all) all=1 ;;
    --volumes) volumes=1 ;;
    --dry-run) dry_run=1; prune=1 ;;
    --yes) yes=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

command -v docker >/dev/null 2>&1 || die 'docker is not installed. Install Docker Desktop or docker-ce.'
docker info >/dev/null 2>&1 || die 'Docker is not running. Start Docker Desktop or the docker service.'
if ((all == 1)); then label='all unused images'; else label='dangling images'; fi

if ((prune == 1)); then
  if ((dry_run == 1)); then
    printf '🔍 Dry run. Nothing will be removed. This would remove:\n' >&2
    printf '   stopped containers: %s\n' "$(docker ps -aq --filter status=exited | wc -l | tr -d ' ')"
    if ((all == 1)); then
      printf '   all images: %s\n' "$(docker images -q | wc -l | tr -d ' ')"
    else
      printf '   dangling images: %s\n' "$(docker images -q --filter dangling=true | wc -l | tr -d ' ')"
    fi
    printf '   custom networks: %s\n' "$(docker network ls -q --filter type=custom | wc -l | tr -d ' ')"
    if ((volumes == 1)); then
      printf '   unused volumes: %s\n' "$(docker volume ls -q --filter dangling=true | wc -l | tr -d ' ')"
    fi
    exit 0
  fi
  printf '🧹 Remove stopped containers, %s and unused networks' "$label" >&2
  if ((volumes == 1)); then printf ', plus unused volumes (data loss)' >&2; fi
  printf '.\n' >&2
  if ((yes == 0)); then
    read -r -p 'Continue? [y/N] ' reply
    [[ "$reply" =~ ^[Yy]$ ]] || { printf '👋 Nothing was removed.\n' >&2; exit 0; }
  fi
  docker container prune -f
  if ((all == 1)); then docker image prune -a -f; else docker image prune -f; fi
  docker network prune -f
  if ((volumes == 1)); then docker volume prune -f; fi
  printf '✅ Clean-up finished.\n' >&2
  printf '\n'
fi
printf '💾 Disk use:\n'
docker system df
printf '\n🖼️  Images:\n'
docker images --format '   {{.Repository}}:{{.Tag}}  {{.Size}}' | head -n 20
