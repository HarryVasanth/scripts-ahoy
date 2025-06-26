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
| [screen-resolution.sh](screen-resolution.sh) | Lists the displays and their current resolutions. | `screen-resolution [-h]` | 2023-03 |
| [dock-reset.sh](dock-reset.sh) | Resets the macOS Dock to its default layout. | `dock-reset [--dry-run] [-y\|--yes] [-h]` | 2024-03 |
| [defaults-backup.sh](defaults-backup.sh) | Exports macOS defaults domains to plist files. | `defaults-backup [--out DIR] [DOMAIN...] [-h]` | 2024-10 |
| [trash-empty.sh](trash-empty.sh) | Empties the Trash after a confirmation. | `trash-empty [--dry-run] [-y\|--yes] [-h]` | 2024-12 |
| [screenshot-organise.sh](screenshot-organise.sh) | Moves screenshots into year and month folders. | `screenshot-organise [--dir DIR] [--dry-run] [-y] [-h]` | 2025-01 |
| [software-update.sh](software-update.sh) | Checks for macOS software updates, or installs them. | `software-update [--install] [--dry-run] [-y\|--yes] [-h]` | 2025-01 |
| [finder-show-hidden.sh](finder-show-hidden.sh) | Toggles or sets hidden file display in Finder. | `finder-show-hidden [--show\|--hide\|--status] [-h]` | 2025-06 |
| [quarantine-clear.sh](quarantine-clear.sh) | Removes the quarantine flag from downloaded files. | `quarantine-clear [--dry-run] [-y] [-r] PATH... [-h]` | 2025-06 |

## Requirements

- Finder
- csrutil
- date
- defaults
- find
- killall
- launchctl
- mdutil
- osascript
- security
- softwareupdate
- spctl
- stat
- system_profiler
- tmutil
- xattr

Shell scripts with options support `--help`.
