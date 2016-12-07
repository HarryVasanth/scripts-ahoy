# 🛡️ Security

Read-only checks for common hardening mistakes.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [login-history.sh](login-history.sh) | Summarise recent logins and failed attempts. | `login-history.sh [-n COUNT] [-h]` | 2016-01 |
| [suid-audit.sh](suid-audit.sh) | List setuid and setgid files. | `suid-audit.sh [PATH...]` | 2016-08 |
| [apparmor-status.sh](apparmor-status.sh) | Show AppArmor profiles and recent denials. | `apparmor-status.sh [-n COUNT] [-h]` | 2016-12 |

## Requirements

- aa-status (Debian and Ubuntu)
- find
- last

Shell scripts with options support `--help`.
