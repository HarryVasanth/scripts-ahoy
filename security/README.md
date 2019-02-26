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

## Requirements

- aa-status (Debian and Ubuntu)
- find
- last
- openssl
- sestatus or getenforce (RHEL family)
- shasum (macOS) or sha256sum (Linux)

Shell scripts with options support `--help`.
