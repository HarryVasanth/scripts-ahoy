# 🛠️ Dev

Project and container chores.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [gitignore-init.sh](gitignore-init.sh) | Write a starter .gitignore for the detected stack. | `gitignore-init [--force] [DIR]` | 2017-03 |
| [compose-health.sh](compose-health.sh) | Wait until every Docker Compose service is running or healthy. | `compose-health [-f FILE] [-t SECONDS]` | 2017-03 |

## Requirements

- Docker Compose (plugin or docker-compose)
- docker

Shell scripts with options support `--help`.
