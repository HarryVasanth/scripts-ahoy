# ☁️ Cloud

Small wrappers for AWS, Kubernetes, and Terraform.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [aws-s3-size.sh](aws-s3-size.sh) | Print the total size of an S3 bucket or prefix. | `aws-s3-size <s3://bucket[/prefix]>` | 2016-07 |
| [gcp-project.sh](gcp-project.sh) | Show or set the active Google Cloud project. | `gcp-project [PROJECT_ID]` | 2017-01 |
| [k8s-secret-keys.sh](k8s-secret-keys.sh) | List the keys in Kubernetes secrets. Values are never shown. | `k8s-secret-keys [--namespace NS] [SECRET]` | 2017-09 |

## Requirements

- aws
- gcloud
- kubectl

Shell scripts with options support `--help`.
