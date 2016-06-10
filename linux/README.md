# 🐧 Linux

Service, disk, and update checks for Linux hosts.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [package-owner.sh](package-owner.sh) | Shows which package owns a file, using apt or rpm. | `package-owner [-h] FILE` | 2016-04 |
| [open-files.sh](open-files.sh) | Shows the processes with the most open files. | `open-files [-n COUNT] [-h]` | 2016-06 |
| [service-wait.sh](service-wait.sh) | Waits until a systemd service is active or failed. | `service-wait [-t SECONDS] UNIT [-h]` | 2016-06 |

## Requirements

- Linux /proc
- dpkg or rpm
- systemctl (systemd)

Shell scripts with options support `--help`.
