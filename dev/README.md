# 🛠️ Dev

Project and container chores.

## Scripts

| Script                                           | What it does                                                              | Usage                                                                                              | Added   |
| ------------------------------------------------ | ------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | ------- |
| [gitignore-init.sh](gitignore-init.sh)           | Write a starter .gitignore for the detected stack.                        | `gitignore-init [--force] [DIR]`                                                                   | 2017-03 |
| [compose-health.sh](compose-health.sh)           | Wait until every Docker Compose service is running or healthy.            | `compose-health [-f FILE] [-t SECONDS]`                                                            | 2017-03 |
| [test-watch.sh](test-watch.sh)                   | Re-run a command when files in a directory change.                        | `test-watch [-d DIR] [-i SECONDS] -- <command...>`                                                 | 2019-05 |
| [makefile-help.sh](makefile-help.sh)             | Print Makefile targets that have a description comment.                   | `makefile-help [-f FILE]`                                                                          | 2019-07 |
| [lint-staged.sh](lint-staged.sh)                 | Run linters on staged files.                                              | `lint-staged`                                                                                      | 2019-09 |
| [license-header.sh](license-header.sh)           | Add an SPDX licence header to source files, or check that one is present. | `license-header [--check] <licence-id> <path>...`                                                  | 2019-09 |
| [port-kill.sh](port-kill.sh)                     | Find the process that listens on a TCP port and stop it.                  | `port-kill [--dry-run] [--force] <port>`                                                           | 2019-12 |
| [docker-prune.sh](docker-prune.sh)               | Clean unused Docker data. The default is a dry run.                       | `docker-prune [--apply] [--all] [--volumes] [--yes] [--dry-run]`                                   | 2020-02 |
| [json-to-env.sh](json-to-env.sh)                 | Turn a JSON document into dotenv lines.                                   | `json-to-env [-f FILE] [--prefix WORD] [--export]`                                                 | 2021-06 |
| [env-example.sh](env-example.sh)                 | Create a .env.example file from .env with the values removed.             | `env-example [--force] [FILE]`                                                                     | 2021-08 |
| [pre-commit-run.sh](pre-commit-run.sh)           | Run the pre-commit hooks on all files.                                    | `pre-commit-run [ARGS...]`                                                                         | 2023-01 |
| [node-version-check.sh](node-version-check.sh)   | Check that the local Node.js version matches the project requirement.     | `node-version-check [--min VERSION] [directory]`                                                   | 2023-09 |
| [todo-scan.sh](todo-scan.sh)                     | Find TODO, FIXME, HACK and XXX notes in a tree of source files.           | `todo-scan [--count] [--tag TAG] [path]`                                                           | 2023-11 |
| [docker-shell.sh](docker-shell.sh)               | Open an interactive shell in a running container.                         | `docker-shell [--shell CMD] <container>`                                                           | 2023-11 |
| [cargo-check.sh](cargo-check.sh)                 | Run cargo check, clippy and a format check.                               | `cargo-check [DIR]`                                                                                | 2024-03 |
| [readme-badges.sh](readme-badges.sh)             | Print Markdown badges for a GitHub repository.                            | `readme-badges --repo OWNER/NAME [--license ID] [--workflow FILE] [--branch NAME] [--tag VERSION]` | 2024-09 |
| [project-bootstrap.sh](project-bootstrap.sh)     | Create a small, standard project skeleton without overwriting files.      | `project-bootstrap [--dry-run] <directory>`                                                        | 2024-11 |
| [env-diff.sh](env-diff.sh)                       | Compare the keys of two dotenv files without showing secret values.       | `env-diff [--strict] <file-a> <file-b>`                                                            | 2024-12 |
| [editorconfig-check.sh](editorconfig-check.sh)   | Check basic .editorconfig rules against files.                            | `editorconfig-check [FILE...]`                                                                     | 2025-02 |
| [venv-create.sh](venv-create.sh)                 | Create a Python virtual environment and print the activate command.       | `venv-create [DIR]`                                                                                | 2025-04 |
| [docker-logs.sh](docker-logs.sh)                 | Follow logs for a container or a Docker Compose service.                  | `docker-logs [--tail N] <name>`                                                                    | 2025-11 |
| [dependency-outdated.sh](dependency-outdated.sh) | Show outdated dependencies for the project in a directory.                | `dependency-outdated [--dir DIR]`                                                                  | 2026-05 |
| [go-mod-tidy.sh](go-mod-tidy.sh)                 | Tidy and verify Go module files.                                          | `go-mod-tidy [DIR]`                                                                                | 2026-11 |

## Requirements

- Docker Compose (plugin or docker-compose)
- cargo (with the clippy and rustfmt components)
- docker
- docker-compose (only for compose services)
- flake8
- git
- go (modules need Go 1.11 or later)
- gofmt
- jq
- jq (jq only reads package.json engines)
- lsof (or ss on Linux)
- node
- plus the linters you use (eslint
- pre-commit
- python3
- shellcheck)
- the package manager that the project uses

Shell scripts with options support `--help`.
