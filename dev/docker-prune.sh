#!/usr/bin/env bash
# Clean unused Docker data. The default is a dry run.
# Usage: docker-prune [--apply] [--all] [--volumes] [--yes] [--dry-run]
# Needs: docker
# Note: Volumes are never removed unless you pass --volumes.
set -euo pipefail

usage() {
  cat << 'EOF'
Usage: docker-prune [--apply] [--all] [--volumes] [--yes] [--dry-run]

Remove stopped containers, dangling images and unused networks.

  --apply     Do the clean-up. Without it, only show what would go.
  --all       Remove all unused images, not just dangling ones.
  --volumes   Also remove unused volumes. This deletes data.
  --yes       Skip the confirmation prompt.
  --dry-run   Show the plan. Change nothing.
  -h, --help  Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

apply=0
all=0
volumes=0
yes=0
while (($# > 0)); do
  case "$1" in
    --apply) apply=1 ;;
    --dry-run) apply=0 ;;
    --all) all=1 ;;
    --volumes) volumes=1 ;;
    -y | --yes) yes=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

command -v docker > /dev/null 2>&1 || die 'docker is not installed. Install Docker Desktop or docker-ce.'
docker info > /dev/null 2>&1 || die 'Docker is not running. Start Docker Desktop or the docker service.'
if ((all == 1)); then image_label='all unused images'; else image_label='dangling images'; fi

if ((apply == 0)); then
  printf '🔍 Dry run. Nothing will be removed.\n' >&2
  printf '🛑 Stopped containers:\n'
  docker ps -a --filter status=created --filter status=exited --filter status=dead \
    --format '   {{.ID}}  {{.Image}}  {{.Names}}'
  printf '\n🖼️  %s:\n' "$image_label"
  if ((all == 1)); then
    docker images --format '   {{.ID}}  {{.Repository}}:{{.Tag}}  {{.Size}}'
  else
    docker images --filter dangling=true --format '   {{.ID}}  {{.Repository}}:{{.Tag}}  {{.Size}}'
  fi
  printf '\n🌐 Unused networks:\n'
  docker network ls --filter type=custom --format '   {{.ID}}  {{.Name}}'
  if ((volumes == 1)); then
    printf '\n💾 Unused volumes:\n'
    docker volume ls --filter dangling=true --format '   {{.Name}}'
  fi
  docker system df
  printf '\n▶️  Run with --apply to clean up.\n' >&2
  exit 0
fi

printf '🧹 Remove stopped containers, %s and unused networks' "$image_label" >&2
if ((volumes == 1)); then printf ', plus unused volumes (data loss)' >&2; fi
printf '.\n' >&2
if ((yes == 0)); then
  read -r -p 'Continue? [y/N] ' reply
  [[ "$reply" =~ ^[Yy]$ ]] || {
    printf '👋 Nothing was removed.\n' >&2
    exit 0
  }
fi

docker container prune -f
if ((all == 1)); then docker image prune -a -f; else docker image prune -f; fi
docker network prune -f
if ((volumes == 1)); then docker volume prune -f; fi
printf '✅ Clean-up finished. Run this script again to see the new usage.\n' >&2
