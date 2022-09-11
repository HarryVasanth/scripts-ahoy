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
| [ssd-trim.sh](ssd-trim.sh) | Report SSD TRIM support and the last trim, or run a trim pass. | `ssd-trim.sh [--run] [--dry-run] [MOUNT...]` | 2019-01 |
| [io-stats.sh](io-stats.sh) | Shows per-device read and write rates from /proc/diskstats. | `io-stats [-i SECONDS] [-n COUNT] [-h]` | 2019-02 |
| [cpu-info.sh](cpu-info.sh) | Shows the CPU model, core count, flags and current frequency. | `cpu-info [-h]` | 2019-08 |
| [cron-lint.sh](cron-lint.sh) | Checks cron files for common mistakes. | `cron-lint [-h]` | 2019-11 |
| [systemd-status.sh](systemd-status.sh) | Shows failed systemd units and the last log lines for each one. | `systemd-status [-a\|--all] [-h\|--help]` | 2020-07 |
| [update-check.sh](update-check.sh) | Counts the package updates that are available. | `update-check [-h]` | 2020-10 |
| [logrotate-check.sh](logrotate-check.sh) | Tests the logrotate configuration in debug mode. | `logrotate-check [CONFIG] [-h]` | 2020-10 |
| [disk-health.sh](disk-health.sh) | Reports disk SMART health and file system usage. | `disk-health [-a\|--all] [-h]` | 2020-12 |
| [kernel-check.sh](kernel-check.sh) | Compares the running kernel with the newest installed one. | `kernel-check [-h]` | 2021-09 |
| [journal-errors.sh](journal-errors.sh) | Shows recent error-level entries from the systemd journal. | `journal-errors [-s\|--since TIME] [-n LINES] [-u\|--unit UNIT] [-h]` | 2021-10 |
| [ntp-status.sh](ntp-status.sh) | Shows the time sync state with timedatectl, chronyc or ntpq. | `ntp-status [-h]` | 2021-12 |
| [memory-report.sh](memory-report.sh) | Summarises RAM, swap and cache use from /proc/meminfo. | `memory-report [-h]` | 2022-04 |
| [apt-cleanup.sh](apt-cleanup.sh) | Removes unused packages and cached files from an apt system. | `apt-cleanup [--dry-run] [-y\|--yes] [-h]` | 2022-09 |

## Requirements

- /etc/passwd
- Linux /proc
- Ubuntu)
- apk
- apt-get (Debian
- awk
- chronyc or ntpq
- df
- dmesg or journalctl
- dnf
- dpkg or rpm
- findmnt (util-linux) or df
- fstrim (util-linux)
- journalctl (systemd)
- logrotate
- lsblk
- lsmod
- one of apt-get
- pacman
- smartctl (smartmontools) for SMART data
- sort
- systemctl
- systemctl (systemd)
- systemd-analyze (optional)
- tail
- timedatectl
- uname
- zypper

Shell scripts with options support `--help`.
