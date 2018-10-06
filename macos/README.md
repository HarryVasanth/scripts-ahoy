# 🍎 macOS

macOS housekeeping with sane defaults and dry runs.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [launchagents.sh](launchagents.sh) | Lists user launch agents and their state. | `launchagents [-h]` | 2017-05 |
| [defaults-tweaks.sh](defaults-tweaks.sh) | Applies a small set of useful macOS defaults settings. | `defaults-tweaks --list \| --apply [--dry-run] [-y] [-h]` | 2017-08 |
| [lock-keychain.sh](lock-keychain.sh) | Locks a macOS keychain at once. | `lock-keychain [PATH] [-h]` | 2018-07 |
| [timemachine-status.sh](timemachine-status.sh) | Shows the Time Machine state, destinations and recent backups. | `timemachine-status [-h]` | 2018-10 |

## Requirements

- defaults
- launchctl
- security
- tmutil

Shell scripts with options support `--help`.
