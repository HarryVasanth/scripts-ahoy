# 🌿 Git

Keep repositories tidy and easy to inspect.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [clean-ignored.sh](clean-ignored.sh) | List or remove ignored files. It is a dry run by default. | `clean-ignored.sh [-f] [-h]` | 2016-05 |
| [hooks-install.sh](hooks-install.sh) | Install git hooks from .githooks into the repository. | `hooks-install.sh [-f] [-h]` | 2016-12 |
| [repo-size.sh](repo-size.sh) | Show the object store and working tree size. | `repo-size.sh [-h]` | 2017-02 |

## Requirements

- du
- git

Shell scripts with options support `--help`.
