# Cost Notes

This project uses AWS resources that can create real charges. The EKS cluster (control plane, billed hourly), EC2 worker nodes, NAT Gateway (billed hourly + per GB processed), LoadBalancers, and public IPv4 addresses may all generate cost.

To control cost:

1. **Set an AWS Budget alarm before running `terraform apply` for the first time.**
2. Only create the environment when actively testing.
3. Follow this loop every session: `terraform plan` → `terraform apply` → test and take screenshots → `terraform destroy`.
4. Never leave the cluster running between sessions.
5. Prefer `t3.small`/`t3.medium` nodes and a small node count (1-3) — this is a learning platform, not a production one.

## Status

As of this build, the Terraform code has been written and reviewed but **not yet applied** — no AWS costs have been incurred by this project so far. See docs/learning-log.md for exactly which steps are code-only vs. actually run.
