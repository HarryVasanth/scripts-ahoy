# 🔎 Recon

Public-source lookups for a domain you own or may test.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [takeover-check.sh](takeover-check.sh) | Check names for CNAME targets that may allow a subdomain takeover. | `takeover-check.sh <name> [name...]` | 2017-07 |
| [sitemap-fetch.sh](sitemap-fetch.sh) | Fetch sitemap.xml and list the URLs that it contains. | `sitemap-fetch.sh <url-or-host>` | 2018-03 |
| [spf-check.sh](spf-check.sh) | Fetch and explain a domain's SPF record. | `spf-check.sh <domain>` | 2019-05 |
| [http-cookies.sh](http-cookies.sh) | Inspect the Set-Cookie flags on a URL. | `http-cookies.sh <url>` | 2019-12 |
| [axfr-check.sh](axfr-check.sh) | Test whether a name server allows a zone transfer. | `axfr-check.sh <domain>` | 2021-01 |
| [cert-info.sh](cert-info.sh) | Show the details of the TLS certificate that a server presents. | `cert-info.sh <host> [port]` | 2023-02 |
| [security-headers.sh](security-headers.sh) | Check common HTTP security headers on a URL. | `security-headers.sh <url>` | 2023-06 |
| [email-harvest.sh](email-harvest.sh) | Collect email addresses from public web pages. | `email-harvest.sh <url> [url...]` | 2023-08 |
| [js-endpoints.sh](js-endpoints.sh) | Extract URLs and paths from JavaScript files. | `js-endpoints.sh <url> [url...]` | 2024-02 |
| [whois-summary.sh](whois-summary.sh) | Summarise the registration data of a domain. | `whois-summary.sh <domain>` | 2024-02 |

## Requirements

- curl
- dig
- openssl
- whois

Shell scripts with options support `--help`.
