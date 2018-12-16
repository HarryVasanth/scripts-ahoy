# 🐧 Linux

Service, disk, and update checks for Linux hosts.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [package-owner.sh](package-owner.sh) | Shows which package owns a file, using apt or rpm. | `package-owner [-h] FILE` | 2016-04 |
| [open-files.sh](open-files.sh) | Shows the processes with the most open files. | `open-files [-n COUNT] [-h]` | 2016-06 |
| [service-wait.sh](service-wait.sh) | Waits until a systemd service is active or failed. | `service-wait [-t SECONDS] UNIT [-h]` | 2016-06 |
| [kernel-modules.sh](kernel-modules.sh) | Lists loaded kernel modules, or shows the parameters of one module. | `kernel-modules [MODULE] [-h]` | 2017-06 |
| [user-audit.sh](user-audit.sh) | Audits local accounts for weak or risky settings. | `user-audit [-h]` | 2017-11 |
| [boot-time.sh](boot-time.sh) | Shows the boot time and the userspace startup duration. | `boot-time [-h]` | 2018-07 |
| [mount-info.sh](mount-info.sh) | Lists mounts with the file system type, size and options. | `mount-info [MOUNTPOINT] [-h]` | 2018-09 |
| [oom-report.sh](oom-report.sh) | Show recent out-of-memory kills on a Linux host. | `oom-report.sh [-n COUNT]` | 2018-11 |
| [load-average.sh](load-average.sh) | Compares the load average with the number of CPUs. | `load-average [-w PCT] [-h]` | 2018-12 |

## Requirements

- /etc/passwd
- Linux /proc
- awk
- dmesg or journalctl
- dpkg or rpm
- findmnt (util-linux) or df
- lsmod
- systemctl (systemd)
- systemd-analyze (optional)

Shell scripts with options support `--help`.
