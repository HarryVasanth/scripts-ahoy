# 🌿 Git

Keep repositories tidy and easy to inspect.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [clean-ignored.sh](clean-ignored.sh) | List or remove ignored files. It is a dry run by default. | `clean-ignored.sh [-f] [-h]` | 2016-05 |
| [hooks-install.sh](hooks-install.sh) | Install git hooks from .githooks into the repository. | `hooks-install.sh [-f] [-h]` | 2016-12 |
| [repo-size.sh](repo-size.sh) | Show the object store and working tree size. | `repo-size.sh [-h]` | 2017-02 |
| [changelog.sh](changelog.sh) | Build a grouped changelog from commit messages. | `changelog.sh [RANGE] [-h]` | 2017-06 |
| [repo-stats.sh](repo-stats.sh) | Show a quick summary of the current repository. | `repo-stats.sh [-h]` | 2017-07 |
| [tag-release.sh](tag-release.sh) | Create an annotated release tag on the latest commit. | `tag-release.sh [-m MESSAGE] TAG` | 2017-08 |
| [remote-prune.sh](remote-prune.sh) | Prune stale remote-tracking branches. | `remote-prune.sh [-n] [REMOTE...]` | 2018-01 |
| [stash-list.sh](stash-list.sh) | List stashes with age and changed files. | `stash-list.sh [-v] [-h]` | 2018-03 |
| [worktree-add.sh](worktree-add.sh) | Add a git worktree for a branch. | `worktree-add.sh BRANCH [-d DIR] [--from REF] [-h]` | 2018-05 |

## Requirements

- du
- git

Shell scripts with options support `--help`.
