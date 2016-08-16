# 🐚 Bash

Small helpers for daily shell work.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [find-large-files.sh](find-large-files.sh) | List the largest files under a directory. | `find-large-files.sh [-n COUNT] [-d DIR] SIZE` | 2015-10 |
| [strip-ansi.sh](strip-ansi.sh) | Remove ANSI colour codes from text. | `strip-ansi.sh [FILE...]` | 2015-12 |
| [rotate-logs.sh](rotate-logs.sh) | Rotate a log file once it passes a size limit. | `rotate-logs.sh [-n COUNT] [-s SIZE] [--dry-run] FILE...` | 2016-01 |
| [retry.sh](retry.sh) | Run a command again until it succeeds. | `retry.sh [-n TRIES] [-d DELAY] [-m MAX] -- COMMAND [ARGS...]` | 2016-02 |
| [checksum-verify.sh](checksum-verify.sh) | Create or check a SHA-256 checksum manifest. | `checksum-verify.sh -g FILE... \| -c MANIFEST` | 2016-03 |
| [dedupe-path.sh](dedupe-path.sh) | Remove duplicate entries from a PATH-style colon list. | `dedupe-path.sh [--export] [-f FILE] [LIST]` | 2016-04 |
| [dir-size.sh](dir-size.sh) | Show the size of each entry in a directory, largest first. | `dir-size.sh [-n COUNT] [DIR]` | 2016-08 |

## Requirements

- sha256sum (Linux) or shasum (macOS)

Shell scripts with options support `--help`.
