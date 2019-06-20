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

## Requirements

- Standard POSIX tools.

Shell scripts with options support `--help`.
