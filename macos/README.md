# 🍎 macOS

macOS housekeeping with sane defaults and dry runs.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [launchagents.sh](launchagents.sh) | Lists user launch agents and their state. | `launchagents [-h]` | 2017-05 |
| [defaults-tweaks.sh](defaults-tweaks.sh) | Applies a small set of useful macOS defaults settings. | `defaults-tweaks --list \| --apply [--dry-run] [-y] [-h]` | 2017-08 |

## Requirements

- defaults
- launchctl

Shell scripts with options support `--help`.
