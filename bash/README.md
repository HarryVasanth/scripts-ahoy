# 🐚 Bash

Small helpers for daily shell work.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [find-large-files.sh](find-large-files.sh) | List the largest files under a directory. | `find-large-files.sh [-n COUNT] [-d DIR] SIZE` | 2015-10 |
| [strip-ansi.sh](strip-ansi.sh) | Remove ANSI colour codes from text. | `strip-ansi.sh [FILE...]` | 2015-12 |
| [rotate-logs.sh](rotate-logs.sh) | Rotate a log file once it passes a size limit. | `rotate-logs.sh [-n COUNT] [-s SIZE] [--dry-run] FILE...` | 2016-01 |

## Requirements

- Standard POSIX tools.

Shell scripts with options support `--help`.
