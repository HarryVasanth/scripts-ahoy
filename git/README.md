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
| [branch-cleanup.sh](branch-cleanup.sh) | Delete local branches that are already merged. | `branch-cleanup.sh [-b BASE] [--delete] [-h]` | 2018-08 |
| [shortlog.sh](shortlog.sh) | Show a contributor summary by commit count. | `shortlog.sh [-n COUNT] [RANGE]` | 2018-11 |
| [undo-commit.sh](undo-commit.sh) | Undo the last commit and keep its changes. | `undo-commit.sh [--unstage] [-y] [-h]` | 2019-10 |
| [commit-activity.sh](commit-activity.sh) | Show commits over time as a bar chart. | `commit-activity.sh [-n COUNT] [-a AUTHOR] [-d] [-h]` | 2020-03 |
| [cherry-pick-range.sh](cherry-pick-range.sh) | Cherry-pick a commit range onto a branch. | `cherry-pick-range.sh [-b BRANCH] [-n] RANGE` | 2020-11 |
| [log-graph.sh](log-graph.sh) | Show a compact graph log with basic filters. | `log-graph.sh [-n COUNT] [-a AUTHOR] [-g PATTERN] [-b BRANCH] [-h]` | 2021-09 |
| [sync-fork.sh](sync-fork.sh) | Update a fork from its upstream remote and push. | `sync-fork.sh [-u UPSTREAM] [-b BRANCH] [--rebase] [-y] [-h]` | 2021-12 |
| [large-files.sh](large-files.sh) | Find the largest files in the git history. | `large-files.sh [-n COUNT] [-h]` | 2022-08 |

## Requirements

- du
- git

Shell scripts with options support `--help`.
