# 🗞️ scripts-ahoy

> Useful Linux, Unix, and macOS scripts, collected since 2015.

A working notebook of shell tools that earned their place. Each script does one job,
prints clear messages, and refuses to guess. Destructive actions need a flag or a
confirmation. Every shell script is checked with ShellCheck.

## Categories

| | Category | Scripts | What it covers |
|---|---|---:|---|
| 🐚 | [Bash](bash/README.md) | 28 | Small helpers for daily shell work. |
| 📝 | [Text](text/README.md) | 20 | Clean, convert, and inspect text and data files. |
| 🌐 | [Network](network/README.md) | 20 | Check links, DNS, ports, and TLS from the command line. |
| 🔎 | [Recon](recon/README.md) | 12 | Public-source lookups for a domain you own or may test. |
| 🛡️ | [Security](security/README.md) | 19 | Read-only checks for common hardening mistakes. |
| 🌿 | [Git](git/README.md) | 22 | Keep repositories tidy and easy to inspect. |
| 🐧 | [Linux](linux/README.md) | 25 | Service, disk, and update checks for Linux hosts. |
| 🍎 | [macOS](macos/README.md) | 12 | macOS housekeeping with sane defaults and dry runs. |
| 🛠️ | [Dev](dev/README.md) | 15 | Project and container chores. |
| 🎬 | [Media](media/README.md) | 17 | Resize, convert, and inspect media without a GUI. |
| ☁️ | [Cloud](cloud/README.md) | 16 | Small wrappers for AWS, Kubernetes, and Terraform. |
| 🧰 | [Proxmox](proxmox/README.md) | 14 | Proxmox VE and PBS maintenance helpers. |

## Quick start

```bash
git clone https://github.com/HarryVasanth/scripts-ahoy.git
cd scripts-ahoy
./bash/find-large-files.sh --help
```

Most scripts support `--help`. Read the header before you run it.

## Requirements

- Bash 3.2 or newer (the macOS default works).
- Common command-line tools. Each script lists what it needs in its header.
- Optional tools such as `jq`, `curl`, `ffmpeg`, and `ImageMagick` for the scripts that use them.

## Notes

- Scripts do not change your system unless you ask. Destructive actions need `--dry-run`, `--force`, or a confirmation.
- Linux-only and macOS-only scripts say so and stop with a clear message on the wrong platform.
- Test a script on a copy of your data first. You know your system best.
