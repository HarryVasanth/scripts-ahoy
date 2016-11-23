# 🌐 Network

Check links, DNS, ports, and TLS from the command line.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [subnet-calc.sh](subnet-calc.sh) | Calculate the addresses of an IPv4 subnet. | `subnet-calc.sh <cidr>` | 2016-07 |
| [tls-expiry.sh](tls-expiry.sh) | Show the days left on a TLS certificate. | `tls-expiry.sh <host> [port]` | 2016-10 |
| [bandwidth-test.sh](bandwidth-test.sh) | Measure download speed against a public test file. | `bandwidth-test.sh [--size <megabytes>] [url]` | 2016-11 |

## Requirements

- awk
- curl
- openssl

Shell scripts with options support `--help`.
