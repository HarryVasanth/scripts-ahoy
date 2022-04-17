# 🍎 macOS

macOS housekeeping with sane defaults and dry runs.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [launchagents.sh](launchagents.sh) | Lists user launch agents and their state. | `launchagents [-h]` | 2017-05 |
| [defaults-tweaks.sh](defaults-tweaks.sh) | Applies a small set of useful macOS defaults settings. | `defaults-tweaks --list \| --apply [--dry-run] [-y] [-h]` | 2017-08 |
| [lock-keychain.sh](lock-keychain.sh) | Locks a macOS keychain at once. | `lock-keychain [PATH] [-h]` | 2018-07 |
| [timemachine-status.sh](timemachine-status.sh) | Shows the Time Machine state, destinations and recent backups. | `timemachine-status [-h]` | 2018-10 |
| [app-list.sh](app-list.sh) | Lists installed applications and their versions. | `app-list [FILTER] [-h]` | 2019-10 |
| [spotlight-status.sh](spotlight-status.sh) | Shows the Spotlight indexing status for each volume. | `spotlight-status [VOLUME] [-h]` | 2019-11 |
| [brew-maintenance.sh](brew-maintenance.sh) | Updates Homebrew and removes old files. | `brew-maintenance [--dry-run] [-y\|--yes] [--no-upgrade] [-h]` | 2020-06 |
| [sip-status.sh](sip-status.sh) | Shows the System Integrity Protection status. | `sip-status [-h]` | 2020-07 |
| [gatekeeper-status.sh](gatekeeper-status.sh) | Shows the Gatekeeper status. | `gatekeeper-status [-h]` | 2020-09 |
| [notify.sh](notify.sh) | Sends a desktop notification from the terminal. | `notify [-t TITLE] [-s SUBTITLE] [-u\|--urgent] MESSAGE [-h]` | 2022-04 |

## Requirements

- csrutil
- defaults
- launchctl
- mdutil
- osascript
- security
- spctl
- tmutil

Shell scripts with options support `--help`.
