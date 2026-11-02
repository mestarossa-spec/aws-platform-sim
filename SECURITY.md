# Accepted risks (lab environment)

Checkov findings deliberately not fixed. Each would be revisited for production.

| Check IDs | Finding | Reason accepted | Production answer |
|---|---|---|---|
| CKV_AWS_2, CKV_AWS_103, CKV_AWS_378 | ALB listener is HTTP | No domain or ACM certificate in the lab | HTTPS listener with ACM, redirect 80 to 443 |
| CKV_AWS_260 | ALB open to 0.0.0.0/0 on port 80 | Public entry point is its purpose | Same, plus WAF |
| CKV_AWS_382 | Task egress open to 0.0.0.0/0 | Tasks pull images through NAT gateway | VPC endpoints for ECR/S3, scoped egress |
| CKV_AWS_150 | ALB deletion protection off | Would block per-session terraform destroy in this lab | Enabled in production |
| CKV_AWS_65 | ECS Container Insights off | Adds a recurring CloudWatch cost for a cluster that lives minutes | Enabled in production |
| CKV_AWS_144 | S3 state bucket has no cross-region replication | Sandbox state, single region | Replicate if state is business critical |
| CKV_AWS_145, CKV_AWS_158, CKV_AWS_26, CKV_AWS_119 | AWS-managed encryption, not customer KMS CMKs | Per-key cost ($1/key/month) and key-policy complexity | CMKs with automatic rotation |
| CKV_AWS_18 | No S3 access logging on state bucket | Needs a separate log bucket with a specific policy | Central log bucket with lifecycle rules |
| CKV_AWS_91 | No ALB access logs | Needs S3 bucket with ALB-specific bucket policy | Central log bucket |
| CKV_AWS_394 | aws_availability_zones not pinned | Minor; would require filter blocks for AZ names | Pin AZ names explicitly |
| CKV_AWS_28 | DynamoDB PITR off on lock table | Low-value fix: lock table holds no recoverable data, only advisory locks | Enabled if state operations are complex |
