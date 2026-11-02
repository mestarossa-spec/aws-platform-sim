# Runbook: Security Group Drift — ALB-to-Task Ingress Rule Removed

## Symptom

- ALB returns **502 Bad Gateway** or **504 Gateway Timeout** (not 503).
- Tasks are running and show as healthy in ECS, but the ALB target group shows targets as **unhealthy**.
- `curl http://<alb-dns>` returns 502.
- Alarm `platform-sim-dev-unhealthy-targets` fires.

**Key tell**: 503 = no task running. 502/504 = task is running but unreachable. This distinction points to network, not compute.

## Detection

1. **ALB target group health**: EC2 → Target Groups → platform-sim-dev-tg → Targets.
   Status: **unhealthy**. Health check failure reason: `Request timed out`.

2. **ECS service**: Tasks show `RUNNING`. No stopped tasks. Service events are quiet.

3. **Security group audit**: EC2 → Security Groups → `platform-sim-dev-task-sg`.
   Expected inbound rule: TCP port 80 from `platform-sim-dev-alb-sg`.
   If that rule is missing → drift confirmed.

4. **Terraform drift detection**:
   ```bash
   cd terraform/envs/dev
   terraform plan   # set TF_VAR_alert_email first
   ```
   Plan will show:
   ```
   ~ aws_security_group.task (in-place update)
     + ingress rule: port 80 from alb-sg   # the missing rule
   ```

## Root Cause

A manual change in the AWS Console removed the ingress rule from `platform-sim-dev-task-sg` that allows the ALB to reach the Fargate tasks.
Terraform did not detect this until `terraform plan` was run.
This is **infrastructure drift** — the live state diverged from the code.

## Fix

**Do not fix manually in the console.** Re-apply Terraform to restore the rule:

```bash
cd terraform/envs/dev
terraform apply   # set TF_VAR_alert_email first
```

Terraform will add back the missing ingress rule. The target group will return to healthy within one health check interval (~30–60 seconds).

Verify:
```bash
curl http://<alb-dns>   # expect 200
```

## Prevention

- **All changes in code**: This incident exists because someone clicked in the console. The fix — running `terraform apply` — is the lesson. Any manual console change is a bug.
- **Drift detection cron**: Schedule `terraform plan` to run daily and alert on non-empty plans. Any `~ change` or `- destroy` in the plan output is a drift signal.
- **AWS Config rule**: Enable `RESTRICTED_INCOMING_TRAFFIC` or a custom Config rule to alert on security group changes outside of Terraform.
- **SCPs / IAM policies**: Deny direct `ec2:AuthorizeSecurityGroupIngress` / `ec2:RevokeSecurityGroupIngress` for the security groups managed by Terraform, except via the Terraform role.

## Why Drill 3 Matters

Drill 1 shows ECS self-healing compute. Drill 2 shows bad deploys. Drill 3 shows the most common real-world incident class: someone "just changed one thing" in the console, and now nothing works. The tool that fixes it is the same tool that describes the system: `terraform apply`.
