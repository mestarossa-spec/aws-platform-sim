# Runbook: Tasks Fail to Start — Bad Container Image

## Symptom

- After a `terraform apply` that changes `container_image`, new tasks stop immediately.
- ALB target group shows 0 healthy targets.
- `curl http://<alb-dns>` returns **503**.
- CloudWatch alarm `platform-sim-dev-unhealthy-targets` fires.

## Detection

1. **ECS Console → Service → Events**: Look for repeated entries like:
   > `service platform-sim-dev-svc: (service) failed to launch a task with (error ECS was unable to assume the role... OR CannotPullContainerError)`

2. **ECS Console → Service → Tasks → Stopped tasks**: Click the stopped task.
   Under **Containers → app → Status Reason** you will see:
   > `CannotPullContainerError: pull image manifest has been retried 1 time(s): failed to resolve ref "public.ecr.aws/nginx/nginx:this-tag-does-not-exist": unexpected status code 404`

3. **CloudWatch alarm**: `platform-sim-dev-unhealthy-targets` in ALARM state.

## Root Cause

A Terraform apply deployed a task definition with an image tag that does not exist in the registry.
ECS launched new tasks with the new task definition; each task failed the image pull and stopped.
The old task (if any) was also replaced, leaving 0 healthy targets.

## Fix

**Rollback immediately** — revert `container_image` in `terraform/envs/dev/main.tf` to the last known-good tag, then apply:

```bash
# In terraform/envs/dev/main.tf, change container_image back to stable:
# container_image = "public.ecr.aws/nginx/nginx:stable"

cd terraform/envs/dev
terraform apply   # set TF_VAR_alert_email first
```

Alternatively, revert the Git commit and re-apply:

```bash
git revert HEAD   # reverts the bad image commit
git push origin issue-4/alarms-and-incidents
cd terraform/envs/dev && terraform apply
```

After apply, verify the replacement task starts and the target goes healthy.

## Prevention

- **Validate image tags before apply**: In CI, run `docker manifest inspect <image>:<tag>` before `terraform apply`.
- **Pin digests for production**: Use `image@sha256:<digest>` instead of a mutable tag. A non-existent digest is caught immediately.
- **Canary deploys**: Use `desired_count = 2` and deploy_circuit_breaker so ECS rolls back automatically if the new task can't start.
- Add an ECS circuit breaker to the `aws_ecs_service` resource:
  ```hcl
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  ```

## Observed (2026-11-02)

- Bad image: `public.ecr.aws/nginx/nginx:this-tag-does-not-exist`
- Applied at ~14:38 UTC. ALB showed 200 briefly (old task still draining), then 503.
- Rollback applied by reverting `container_image` to `stable` in `main.tf`.
