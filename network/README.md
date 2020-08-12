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
| [dns-benchmark.sh](dns-benchmark.sh) | Time DNS answers from several public resolvers. | `dns-benchmark.sh [domain] [resolver...]` | 2019-03 |
| [http-methods.sh](http-methods.sh) | Probe which HTTP methods a URL allows. | `http-methods.sh [--yes] <url>` | 2020-04 |
| [port-scan.sh](port-scan.sh) | Scan a port range on one host that you own. | `port-scan.sh [--yes] <host> <start>-<end>` | 2020-05 |
| [lan-scan.sh](lan-scan.sh) | Find devices on the local network and show their MAC addresses. | `lan-scan.sh [--yes] [--dry-run] [cidr]` | 2020-05 |
| [http-headers.sh](http-headers.sh) | Show response headers and check common security headers. | `http-headers.sh <url>` | 2020-08 |

## Requirements

- Debian: apt install dnsutils)
- arp
- awk
- curl
- dd
- dig
- dig (macOS: brew install bind
- nc
- nc (falls back to bash /dev/tcp)
- openssl
- ping

Shell scripts with options support `--help`.
