# 🌐 Network

Check links, DNS, ports, and TLS from the command line.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [subnet-calc.sh](subnet-calc.sh) | Calculate the addresses of an IPv4 subnet. | `subnet-calc.sh <cidr>` | 2016-07 |
| [tls-expiry.sh](tls-expiry.sh) | Show the days left on a TLS certificate. | `tls-expiry.sh <host> [port]` | 2016-10 |
| [bandwidth-test.sh](bandwidth-test.sh) | Measure download speed against a public test file. | `bandwidth-test.sh [--size <megabytes>] [url]` | 2016-11 |
| [port-check.sh](port-check.sh) | Check which TCP ports answer on a host. | `port-check.sh <host> [ports] [timeout]` | 2017-10 |
| [speed-test.sh](speed-test.sh) | Measure download and upload throughput with curl. | `speed-test.sh [--size <megabytes>]` | 2017-11 |
| [public-ip.sh](public-ip.sh) | Show the public IP address that this machine uses. | `public-ip.sh [--4\|--6]` | 2018-01 |
| [dns-lookup.sh](dns-lookup.sh) | Look up DNS records for a name. | `dns-lookup.sh <name> [type] [resolver]` | 2018-02 |

## Requirements

- Debian: apt install dnsutils)
- awk
- curl
- dd
- dig (macOS: brew install bind
- nc (falls back to bash /dev/tcp)
- openssl

Shell scripts with options support `--help`.
