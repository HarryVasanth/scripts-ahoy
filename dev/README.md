# 🛠️ Dev

Project and container chores.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [gitignore-init.sh](gitignore-init.sh) | Write a starter .gitignore for the detected stack. | `gitignore-init [--force] [DIR]` | 2017-03 |
| [compose-health.sh](compose-health.sh) | Wait until every Docker Compose service is running or healthy. | `compose-health [-f FILE] [-t SECONDS]` | 2017-03 |
| [test-watch.sh](test-watch.sh) | Re-run a command when files in a directory change. | `test-watch [-d DIR] [-i SECONDS] -- <command...>` | 2019-05 |
| [makefile-help.sh](makefile-help.sh) | Print Makefile targets that have a description comment. | `makefile-help [-f FILE]` | 2019-07 |
| [lint-staged.sh](lint-staged.sh) | Run linters on staged files. | `lint-staged` | 2019-09 |
| [license-header.sh](license-header.sh) | Add an SPDX licence header to source files, or check that one is present. | `license-header [--check] <licence-id> <path>...` | 2019-09 |
| [port-kill.sh](port-kill.sh) | Find the process that listens on a TCP port and stop it. | `port-kill [--dry-run] [--force] <port>` | 2019-12 |
| [docker-prune.sh](docker-prune.sh) | Clean unused Docker data. The default is a dry run. | `docker-prune [--apply] [--all] [--volumes] [--yes] [--dry-run]` | 2020-02 |
| [json-to-env.sh](json-to-env.sh) | Turn a JSON document into dotenv lines. | `json-to-env [-f FILE] [--prefix WORD] [--export]` | 2021-06 |
| [env-example.sh](env-example.sh) | Create a .env.example file from .env with the values removed. | `env-example [--force] [FILE]` | 2021-08 |
| [pre-commit-run.sh](pre-commit-run.sh) | Run the pre-commit hooks on all files. | `pre-commit-run [ARGS...]` | 2023-01 |

## Requirements

- Docker Compose (plugin or docker-compose)
- docker
- flake8
- git
- gofmt
- jq
- lsof (or ss on Linux)
- plus the linters you use (eslint
- pre-commit
- shellcheck)

Shell scripts with options support `--help`.
