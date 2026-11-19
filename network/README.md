# 🌐 Network

Check links, DNS, ports, and TLS from the command line.

## Scripts

| Script                                         | What it does                                                             | Usage                                                          | Added   |
| ---------------------------------------------- | ------------------------------------------------------------------------ | -------------------------------------------------------------- | ------- |
| [subnet-calc.sh](subnet-calc.sh)               | Calculate the addresses of an IPv4 subnet.                               | `subnet-calc.sh <cidr>`                                        | 2016-07 |
| [tls-expiry.sh](tls-expiry.sh)                 | Show the days left on a TLS certificate.                                 | `tls-expiry.sh <host> [port]`                                  | 2016-10 |
| [bandwidth-test.sh](bandwidth-test.sh)         | Measure download speed against a public test file.                       | `bandwidth-test.sh [--size <megabytes>] [url]`                 | 2016-11 |
| [port-check.sh](port-check.sh)                 | Check which TCP ports answer on a host.                                  | `port-check.sh <host> [ports] [timeout]`                       | 2017-10 |
| [speed-test.sh](speed-test.sh)                 | Measure download and upload throughput with curl.                        | `speed-test.sh [--size <megabytes>]`                           | 2017-11 |
| [public-ip.sh](public-ip.sh)                   | Show the public IP address that this machine uses.                       | `public-ip.sh [--4\|--6]`                                      | 2018-01 |
| [dns-lookup.sh](dns-lookup.sh)                 | Look up DNS records for a name.                                          | `dns-lookup.sh <name> [type] [resolver]`                       | 2018-02 |
| [dns-benchmark.sh](dns-benchmark.sh)           | Time DNS answers from several public resolvers.                          | `dns-benchmark.sh [domain] [resolver...]`                      | 2019-03 |
| [http-methods.sh](http-methods.sh)             | Probe which HTTP methods a URL allows.                                   | `http-methods.sh [--yes] <url>`                                | 2020-04 |
| [port-scan.sh](port-scan.sh)                   | Scan a port range on one host that you own.                              | `port-scan.sh [--yes] <host> <start>-<end>`                    | 2020-05 |
| [lan-scan.sh](lan-scan.sh)                     | Find devices on the local network and show their MAC addresses.          | `lan-scan.sh [--yes] [--dry-run] [cidr]`                       | 2020-05 |
| [http-headers.sh](http-headers.sh)             | Show response headers and check common security headers.                 | `http-headers.sh <url>`                                        | 2020-08 |
| [ping-sweep.sh](ping-sweep.sh)                 | Ping every address in a small block and list the replies.                | `ping-sweep.sh [--yes] [--dry-run] <cidr>`                     | 2020-09 |
| [http-timing.sh](http-timing.sh)               | Show DNS, connect, TLS, and first-byte timing for a URL.                 | `http-timing.sh <url>`                                         | 2021-05 |
| [netstat-summary.sh](netstat-summary.sh)       | Summarise the listening TCP and UDP sockets on this host.                | `netstat-summary.sh`                                           | 2022-01 |
| [tcpdump-capture.sh](tcpdump-capture.sh)       | Capture network traffic to a pcap file with a filter.                    | `tcpdump-capture.sh [-i <interface>] [-c <count>] <filter...>` | 2022-03 |
| [traceroute-summary.sh](traceroute-summary.sh) | Summarise the route to a host: hop count, loss and last reply.           | `traceroute-summary.sh <host> [max-hops]`                      | 2023-04 |
| [wol.sh](wol.sh)                               | Send a Wake-on-LAN magic packet to a MAC address.                        | `wol.sh [--dry-run] <mac> [broadcast] [port]`                  | 2023-07 |
| [ping-stats.sh](ping-stats.sh)                 | Show packet loss and the min, avg, and max latency to a host.            | `ping-stats.sh [count] <host>`                                 | 2023-08 |
| [wifi-info.sh](wifi-info.sh)                   | Show the current Wi-Fi network name and signal strength.                 | `wifi-info.sh`                                                 | 2024-06 |
| [dns-propagation.sh](dns-propagation.sh)       | Ask several public resolvers for one DNS record and compare the answers. | `dns-propagation.sh <name> [type]`                             | 2024-10 |
| [ssh-banner.sh](ssh-banner.sh)                 | Read the SSH banner and software version from a host.                    | `ssh-banner.sh <host> [port]`                                  | 2025-10 |
| [redirect-chain.sh](redirect-chain.sh)         | Show each redirect hop and the final URL for a link.                     | `redirect-chain.sh <url> [max-hops]`                           | 2025-12 |

## Requirements

- Debian: apt install dnsutils)
- arp
- awk
- curl
- dd
- dig
- dig (macOS: brew install bind
- lsof
- nc
- nc (falls back to bash /dev/tcp)
- openssl
- or netstat
- ping
- ss
- system_profiler (macOS) or iw/nmcli (Linux)
- tcpdump
- traceroute

Shell scripts with options support `--help`.
