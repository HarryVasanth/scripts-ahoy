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
| [ct-start.sh](ct-start.sh) | Start a container and wait until it reports running. | `ct-start [-H user@host] [-t SECONDS] CTID` | 2021-03 |
| [vm-snapshot.sh](vm-snapshot.sh) | Take, list or delete snapshots of one VM. | `vm-snapshot [-l] [-d NAME] [--dry-run] [-y] [-H user@host] VMID [NAME]` | 2021-11 |
| [pve7-post-install.sh](pve/pve7-post-install.sh) | Set up a fresh Proxmox VE 7 host: free repos, no nag screen, useful tools. | `sudo ./pve7-post-install.sh` | 2022-06 |
| [pbs2-post-install.sh](pbs/pbs2-post-install.sh) | Set up a fresh Proxmox Backup Server 2 host: free repos and no nag screen. | `sudo ./pbs2-post-install.sh` | 2022-06 |

## Requirements

- jq (Proxmox VE)
- pct (Proxmox VE)
- pvesh
- pvesm (Proxmox VE)
- qm (Proxmox VE)

Shell scripts with options support `--help`.
