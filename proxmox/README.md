# 🧰 Proxmox

Proxmox VE and PBS maintenance helpers.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [vm-stop.sh](vm-stop.sh) | Shut down a VM, or stop it at once with --force. | `vm-stop [-H user@host] [-f] [--dry-run] [-y] VMID` | 2016-02 |
| [ct-stop.sh](ct-stop.sh) | Stop a container, or stop it at once with --force. | `ct-stop [-H user@host] [-f] [--dry-run] [-y] CTID` | 2018-06 |
| [backup-list.sh](backup-list.sh) | List backup files in a Proxmox storage. | `backup-list [-H user@host] [-s STORAGE] [--vmid VMID]` | 2019-01 |
| [task-list.sh](task-list.sh) | Show recent tasks from the cluster task log. | `task-list [-H user@host] [-n LIMIT]` | 2020-02 |
| [vm-start.sh](vm-start.sh) | Start a VM and wait until it reports running. | `vm-start [-H user@host] [-t SECONDS] VMID` | 2020-06 |

## Requirements

- jq (Proxmox VE)
- pct (Proxmox VE)
- pvesh
- pvesm (Proxmox VE)
- qm (Proxmox VE)

Shell scripts with options support `--help`.
