# ☁️ Cloud

Small wrappers for AWS, Kubernetes, and Terraform.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [aws-s3-size.sh](aws-s3-size.sh) | Print the total size of an S3 bucket or prefix. | `aws-s3-size <s3://bucket[/prefix]>` | 2016-07 |
| [gcp-project.sh](gcp-project.sh) | Show or set the active Google Cloud project. | `gcp-project [PROJECT_ID]` | 2017-01 |
| [k8s-secret-keys.sh](k8s-secret-keys.sh) | List the keys in Kubernetes secrets. Values are never shown. | `k8s-secret-keys [--namespace NS] [SECRET]` | 2017-09 |
| [aws-iam-audit.sh](aws-iam-audit.sh) | Report IAM users without MFA and access keys older than 90 days. | `aws-iam-audit` | 2018-02 |
| [compose-pull.sh](compose-pull.sh) | Pull images for a Docker Compose project. | `compose-pull [-f FILE] [SERVICE...]` | 2018-05 |
| [helm-list.sh](helm-list.sh) | List Helm releases across namespaces. | `helm-list [--namespace NS]` | 2020-08 |
| [s3-sync.sh](s3-sync.sh) | Sync a local path to S3. It is a dry run unless you pass --apply. | `s3-sync [--apply] [--delete] [--exclude GLOB] [--yes] SOURCE s3://BUCKET/PREFIX` | 2020-11 |
| [gcloud-config.sh](gcloud-config.sh) | List, show or activate gcloud configurations. | `gcloud-config [--current] [CONFIGURATION]` | 2021-04 |
| [terraform-plan.sh](terraform-plan.sh) | Run terraform init and plan, and save the plan file. | `terraform-plan [--out FILE] [DIR]` | 2022-05 |
| [k8s-events.sh](k8s-events.sh) | Show recent warning events in the cluster. | `k8s-events [--tail N] [--namespace NS]` | 2022-06 |
| [k8s-logs.sh](k8s-logs.sh) | Follow logs for one pod or for pods that match a label. | `k8s-logs [-n NS] [-p POD \| -l SELECTOR] [-c CONTAINER] [--since DUR] [--tail N] [--previous]` | 2022-12 |
| [terraform-fmt.sh](terraform-fmt.sh) | Check or apply terraform fmt across a directory tree. | `terraform-fmt [--write] [--diff] [directory]` | 2023-03 |

## Requirements

- aws
- docker-compose
- gcloud
- helm 3
- kubectl
- terraform

Shell scripts with options support `--help`.
