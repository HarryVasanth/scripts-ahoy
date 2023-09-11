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
| [batch-rename.sh](batch-rename.sh) | Rename many files with one sed pattern. | `batch-rename.sh [--apply] [-E] PATTERN REPLACEMENT FILE...` | 2016-09 |
| [log-tail.sh](log-tail.sh) | Show the end of several log files with a label on each line. | `log-tail.sh [-n LINES] [-f] FILE...` | 2018-04 |
| [backup-dir.sh](backup-dir.sh) | Make a dated tar.gz backup of a directory and prune old copies. | `backup-dir.sh [-o OUTDIR] [-k KEEP] DIR` | 2018-12 |
| [calc.sh](calc.sh) | Do safe arithmetic on an expression with awk. | `calc.sh EXPRESSION` | 2019-04 |
| [timestamp.sh](timestamp.sh) | Show the current time, or convert an epoch, in a useful format. | `timestamp.sh [--epoch\|--iso\|--file] [--utc] [EPOCH]` | 2019-04 |
| [wait-for-port.sh](wait-for-port.sh) | Wait until a TCP port accepts connections. | `wait-for-port.sh [-t TIMEOUT] [-i INTERVAL] [-q] HOST PORT` | 2020-01 |
| [human-size.sh](human-size.sh) | Convert bytes to a human size, or a human size back to bytes. | `human-size.sh [-b] VALUE` | 2020-03 |
| [ask.sh](ask.sh) | Ask a yes/no question and return the answer as an exit code. | `ask.sh [-y\|-n] PROMPT...` | 2021-02 |
| [find-dupes.sh](find-dupes.sh) | Find duplicate files by SHA-256 in a directory tree. | `find-dupes.sh [DIR]` | 2021-04 |
| [sudo-keepalive.sh](sudo-keepalive.sh) | Keep the sudo timestamp fresh while a command runs. | `sudo-keepalive.sh COMMAND [ARGS...]` | 2021-10 |
| [random-password.sh](random-password.sh) | Make strong random passwords from /dev/urandom. | `random-password.sh [-l LENGTH] [-c COUNT] [--no-symbols]` | 2022-01 |
| [shellcheck-all.sh](shellcheck-all.sh) | Run ShellCheck on every shell script in a tree. | `shellcheck-all.sh [-d DIR]` | 2022-02 |
| [serve-http.sh](serve-http.sh) | Serve a directory over HTTP with the Python standard library. | `serve-http.sh [-p PORT] [-b ADDRESS] [DIR]` | 2022-03 |
| [clean-temp.sh](clean-temp.sh) | Delete old items from a temporary directory. | `clean-temp.sh [-d DAYS] [--dry-run] [--yes] [DIR]` | 2022-07 |
| [shell-info.sh](shell-info.sh) | Show the current shell, its version, its options, and a PATH summary. | `shell-info.sh` | 2022-10 |
| [date-math.sh](date-math.sh) | Add or subtract days from a date. | `date-math.sh [-b YYYY-MM-DD] OFFSET` | 2022-12 |
| [parse_filelist.sh](parse_filelist.sh) | Call a command for each directory listed in a text file. | `./parse_filelist.sh FILE COMMAND TEXT` | 2023-01 |
| [ssh_tar.sh](ssh_tar.sh) | Copy a folder over SSH with tar. This is faster than a plain recursive copy for many small files. | `./ssh_tar.sh user@host /path/to/folder` | 2023-01 |
| [uncomment.sed](uncomment.sed) | Remove the leading comment marker from a block of shell or config lines. | `./uncomment.sed FILE` | 2023-01 |
| [wc.sh](wc.sh) | Count words and lines in files of one or more types. | `./wc.sh DIR EXT [EXT...]` | 2023-01 |
| [file-age.sh](file-age.sh) | List the oldest and newest files by modification time. | `file-age.sh [-n COUNT] [DIR]` | 2023-09 |

## Requirements

- python3
- sha256sum (Linux) or shasum (macOS)
- shellcheck
- sudo

Shell scripts with options support `--help`.
