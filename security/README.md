# 🛡️ Security

Read-only checks for common hardening mistakes.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [login-history.sh](login-history.sh) | Summarise recent logins and failed attempts. | `login-history.sh [-n COUNT] [-h]` | 2016-01 |
| [suid-audit.sh](suid-audit.sh) | List setuid and setgid files. | `suid-audit.sh [PATH...]` | 2016-08 |
| [apparmor-status.sh](apparmor-status.sh) | Show AppArmor profiles and recent denials. | `apparmor-status.sh [-n COUNT] [-h]` | 2016-12 |
| [openssl-audit.sh](openssl-audit.sh) | Check a host for weak TLS protocols and ciphers. | `openssl-audit.sh [-p PORT] HOST` | 2017-04 |
| [password-age.sh](password-age.sh) | Report local accounts with old or missing passwords. | `password-age.sh [-f SHADOW] [-d DAYS] [-h]` | 2018-04 |
| [selinux-status.sh](selinux-status.sh) | Show the SELinux mode and recent denials. | `selinux-status.sh [-n COUNT] [-h]` | 2018-10 |
| [hash-check.sh](hash-check.sh) | Print or verify SHA-256 checksums. | `hash-check.sh FILE... > SHA256SUMS` | 2019-02 |
| [ssh-hardening-check.sh](ssh-hardening-check.sh) | Check an sshd config for weak or risky settings. | `ssh-hardening-check.sh [-f CONFIG] [-h]` | 2019-06 |
| [open-ports.sh](open-ports.sh) | List listening TCP and bound UDP ports. | `open-ports.sh [-h]` | 2020-04 |
| [secret-scan.sh](secret-scan.sh) | Scan files for likely secrets and show only their location. | `secret-scan.sh [-q] [PATH...] [-h]` | 2021-01 |
| [gpg-backup.sh](gpg-backup.sh) | Back up GnuPG public keys and trust settings. | `gpg-backup.sh [-o DIR] [-u KEYID] [-f] [-h]` | 2021-02 |
| [cert-pin.sh](cert-pin.sh) | Show the SHA-256 public key pin for a TLS certificate. | `cert-pin.sh [-p PORT] [-s NAME] HOST` | 2021-08 |
| [filevault-status.sh](filevault-status.sh) | Report full-disk encryption status. | `filevault-status.sh [-h]` | 2022-02 |
| [firewall-status.sh](firewall-status.sh) | Show the state of the local firewall. | `firewall-status.sh [-h]` | 2022-05 |
| [ssh-keys-audit.sh](ssh-keys-audit.sh) | Audit SSH authorised keys files for permissions and options. | `ssh-keys-audit.sh [-h]` | 2022-09 |
| [failed-logins.sh](failed-logins.sh) | Summarise failed login attempts from system logs. | `failed-logins.sh [-f LOGFILE] [-n COUNT] [-h]` | 2022-10 |
| [umask-check.sh](umask-check.sh) | Show the current and configured umask. | `umask-check.sh [-h]` | 2023-02 |
| [kernel-hardening.sh](kernel-hardening.sh) | Check key kernel settings for hardening. | `kernel-hardening.sh [-h]` | 2024-05 |
| [password-policy.sh](password-policy.sh) | Check the PAM password quality policy. | `password-policy.sh [-h]` | 2024-07 |
| [sudoers-audit.sh](sudoers-audit.sh) | Audit sudoers rules for risky settings. | `sudoers-audit.sh [-d DIR] [-h]` | 2025-09 |

## Requirements

- aa-status (Debian and Ubuntu)
- awk
- find
- gpg
- last
- openssl
- sestatus or getenforce (RHEL family)
- shasum (macOS) or sha256sum (Linux)
- stat
- sysctl

Shell scripts with options support `--help`.
