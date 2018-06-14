# 🧰 Proxmox

Proxmox VE and PBS maintenance helpers.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [vm-stop.sh](vm-stop.sh) | Shut down a VM, or stop it at once with --force. | `vm-stop [-H user@host] [-f] [--dry-run] [-y] VMID` | 2016-02 |
| [ct-stop.sh](ct-stop.sh) | Stop a container, or stop it at once with --force. | `ct-stop [-H user@host] [-f] [--dry-run] [-y] CTID` | 2018-06 |

## Requirements

- pct (Proxmox VE)
- qm (Proxmox VE)

Shell scripts with options support `--help`.
