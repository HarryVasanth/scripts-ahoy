# 📝 Text

Clean, convert, and inspect text and data files.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [csv-to-json.sh](csv-to-json.sh) | Turn a simple CSV file into a JSON array of objects. | `csv-to-json.sh [--numbers] [FILE]` | 2015-11 |
| [case-convert.sh](case-convert.sh) | Convert text between common naming cases. | `case-convert.sh --to STYLE [TEXT...]` | 2016-05 |
| [csv-column.sh](csv-column.sh) | Select or reorder CSV columns by name. | `csv-column.sh -c NAME[,NAME...] [FILE]` | 2016-09 |
| [sort-csv.sh](sort-csv.sh) | Sort CSV rows by a column and keep the header on top. | `sort-csv.sh [-c COLUMN] [-n] [-r] [FILE]` | 2016-10 |

## Requirements

- Standard POSIX tools.

Shell scripts with options support `--help`.
