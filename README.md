# aws-platform-sim

A one-person platform team simulator using AWS and Terraform.

## What exists

| Path | Purpose |
|------|---------|
| `terraform/` | All infrastructure as code |
| `runbooks/` | Incident runbooks (symptom → fix) |

## Bootstrap state

Remote Terraform state lives in S3 (versioned, encrypted, public access blocked)  
with DynamoDB for state locking.

## Rules

- Never push to `main` directly — all work via PRs.
- Run `terraform destroy` at the end of every session.
- Each incident gets a runbook in `runbooks/`.

## Tools required

- AWS CLI v2
- Terraform >= 1.0
- Git
- GitHub CLI (`gh`)
