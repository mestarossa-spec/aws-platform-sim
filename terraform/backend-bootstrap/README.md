# Terraform Backend Bootstrap

Provisions the remote state infrastructure. Run this **once** before any other module.

## What it creates

| Resource | Name | Purpose |
|----------|------|---------|
| S3 bucket | `aws-platform-sim-tfstate-038269110424` | Stores `.tfstate` files |
| S3 versioning | enabled | Lets you recover old state |
| S3 encryption | AES256 | State at rest is encrypted |
| S3 public access block | all blocked | No accidental public exposure |
| DynamoDB table | `aws-platform-sim-tflock` | Prevents concurrent `terraform apply` |

## Why

Terraform state contains secrets and resource IDs. Keeping it in S3 with versioning means you can roll back a bad apply. DynamoDB locking prevents two applies running at the same time and corrupting state.

## Usage

```bash
cd terraform/backend-bootstrap
terraform init
terraform apply
```

After apply, copy the `backend_config` output into any other module's `terraform {}` block.

## Destroy

```bash
terraform destroy
# Then manually empty and delete the S3 bucket (versioned buckets need bucket emptied first)
```
