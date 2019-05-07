# 🔎 Recon

Public-source lookups for a domain you own or may test.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [takeover-check.sh](takeover-check.sh) | Check names for CNAME targets that may allow a subdomain takeover. | `takeover-check.sh <name> [name...]` | 2017-07 |
| [sitemap-fetch.sh](sitemap-fetch.sh) | Fetch sitemap.xml and list the URLs that it contains. | `sitemap-fetch.sh <url-or-host>` | 2018-03 |
| [spf-check.sh](spf-check.sh) | Fetch and explain a domain's SPF record. | `spf-check.sh <domain>` | 2019-05 |

## Requirements

- curl
- dig

Shell scripts with options support `--help`.
