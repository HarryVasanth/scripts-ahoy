# 📝 Text

Clean, convert, and inspect text and data files.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [csv-to-json.sh](csv-to-json.sh) | Turn a simple CSV file into a JSON array of objects. | `csv-to-json.sh [--numbers] [FILE]` | 2015-11 |
| [case-convert.sh](case-convert.sh) | Convert text between common naming cases. | `case-convert.sh --to STYLE [TEXT...]` | 2016-05 |
| [csv-column.sh](csv-column.sh) | Select or reorder CSV columns by name. | `csv-column.sh -c NAME[,NAME...] [FILE]` | 2016-09 |
| [sort-csv.sh](sort-csv.sh) | Sort CSV rows by a column and keep the header on top. | `sort-csv.sh [-c COLUMN] [-n] [-r] [FILE]` | 2016-10 |
| [markdown-toc.sh](markdown-toc.sh) | Build a table of contents from the headings in a Markdown file. | `markdown-toc.sh [-l LEVEL] [FILE]` | 2017-01 |
| [slugify.sh](slugify.sh) | Turn text into a URL-friendly slug. | `slugify.sh [-s SEP] [TEXT...]` | 2017-02 |
| [split-csv.sh](split-csv.sh) | Split a CSV file into parts, repeating the header row. | `split-csv.sh [-r ROWS] [-n PARTS] [--force] FILE` | 2017-04 |
| [replace-in-files.sh](replace-in-files.sh) | Replace text in many files, with a safe preview first. | `replace-in-files.sh [--apply] [-E] PATTERN REPLACEMENT FILE...` | 2017-12 |
| [tab-to-space.sh](tab-to-space.sh) | Convert tabs to spaces, or spaces to tabs. | `tab-to-space.sh [-s] [-w WIDTH] [FILE...]` | 2019-03 |
| [strip-html.sh](strip-html.sh) | Remove HTML tags and decode common entities. | `strip-html.sh [FILE...]` | 2019-06 |
| [json-pretty.sh](json-pretty.sh) | Pretty-print, compact, or sort a JSON file. | `json-pretty.sh [-c] [-s] [FILE]` | 2019-08 |
| [json-to-csv.sh](json-to-csv.sh) | Flatten a simple JSON array of objects into CSV. | `json-to-csv.sh [FILE]` | 2020-01 |
| [reading-time.sh](reading-time.sh) | Estimate how long a text takes to read. | `reading-time.sh [-w WPM] [FILE...]` | 2021-05 |
| [extract-urls.sh](extract-urls.sh) | Pull URLs out of text. | `extract-urls.sh [-a] [FILE...]` | 2021-06 |
| [join-lines.sh](join-lines.sh) | Join all lines into one line with a separator. | `join-lines.sh [-s SEP] [FILE...]` | 2021-07 |
| [column-align.sh](column-align.sh) | Line up columns of text for a clean plain-text table. | `column-align.sh [-s SEP] [-r] [FILE]` | 2021-11 |
| [extract-emails.sh](extract-emails.sh) | Pull email addresses out of text files. | `extract-emails.sh [-a] [-c] [FILE...]` | 2022-06 |
| [diff-words.sh](diff-words.sh) | Show a word-level diff of two files. | `diff-words.sh FILE1 FILE2` | 2022-08 |
| [dedupe-lines.sh](dedupe-lines.sh) | Remove duplicate lines from text while keeping the first order. | `dedupe-lines.sh [-c] [-d] [FILE]` | 2022-11 |
| [base64-file.sh](base64-file.sh) | Encode or decode a file with base64. | `base64-file.sh [-d] [-o OUT] [FILE]` | 2023-04 |
| [wrap-text.sh](wrap-text.sh) | Wrap long lines to a chosen width. | `wrap-text.sh [-w WIDTH] [FILE...]` | 2024-11 |
| [markdown-lint.sh](markdown-lint.sh) | Check Markdown files for common problems. | `markdown-lint.sh [FILE...]` | 2025-03 |

## Requirements

- git
- jq

Shell scripts with options support `--help`.
