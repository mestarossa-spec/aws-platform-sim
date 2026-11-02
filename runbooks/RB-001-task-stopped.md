# Runbook: ECS Task Stopped / Service Self-Healing

## Symptom

ALB returns **503 Service Temporarily Unavailable** for up to 60–90 seconds.
After recovery, `curl http://<alb-dns>` returns 200 again.

## Detection

- **CloudWatch alarm**: `platform-sim-dev-unhealthy-targets` fires (UnHealthyHostCount > 0 for 2 periods).
- **ECS Console**: ECS → Clusters → platform-sim-dev-cluster → Services → platform-sim-dev-svc → Events tab shows a "task stopped" event followed by a "task started" event.
- **ALB target group**: EC2 → Target Groups → platform-sim-dev-tg → Targets tab shows 0 healthy targets briefly, then 1.

## Root Cause

The Fargate task was stopped (manually, by OOM, or by a health check failure).
ECS service scheduler detected the desired count (1) was not met and launched a replacement.

## Fix

No action needed — ECS self-healed. Verify the replacement task is running:

```bash
aws ecs list-tasks --cluster platform-sim-dev-cluster \
  --service-name platform-sim-dev-svc --region ap-southeast-2
```

If the replacement task also stops immediately, escalate to Drill 1b (crash loop — check CloudWatch logs):

```bash
aws logs tail /ecs/platform-sim-dev --since 10m --region ap-southeast-2
```

## Prevention

- Set `desired_count = 2` for production to eliminate single-task outages.
- Add a CloudWatch alarm on `RunningTaskCount < 1` to catch crash loops before the replacement also fails.
- Health check settings (interval 30s, threshold 2) give the task ~60s to recover before the alarm fires.

## Observed (2026-11-02)

- Task stopped at ~14:37 UTC.
- New task ARN: `fd443bc30fef4f1cbc36001fdb744255`.
- 503 lasted approximately 60 seconds.
- HTTP 200 confirmed after replacement was healthy.
