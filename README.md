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

## CI

Every PR touching `terraform/**` runs four checks with no AWS credentials:

| Check | What it does |
|-------|-------------|
| `terraform fmt` | Fails on formatting drift |
| `terraform init -backend=false` + `validate` | Catches syntax errors and bad references |
| `tflint` | Linting (unused variables, deprecated syntax) |
| Checkov | Security findings — report-only (`soft_fail: true`) |

CI runs without AWS credentials because `init -backend=false` skips the S3 backend entirely. In a production org, `plan` would run on PRs and `apply` behind an approval gate, authenticated via a GitHub OIDC role with scoped IAM permissions (no stored keys). The IAM Identity Provider feature needed for OIDC requires org-level IAM access not available on this sandbox account.

## Tools required

- AWS CLI v2
- Terraform >= 1.0
- Git
- GitHub CLI (`gh`)
