# Learning Log

## Day 1

Started AutoGitOps Platform to learn how Kubernetes platforms are built and operated on AWS: Terraform, EKS, GitOps with ArgoCD, and observability with Prometheus/Grafana. This project is deliberately kept separate from AutoSecureOps (Project 1) — that one proves DevSecOps around an application, this one proves the ability to build the platform such an application runs on.

Scaffolded the repo structure (terraform/{bootstrap,environments/dev,modules}, apps/, argocd/, monitoring/, tests/, docs/) and wrote the first pass of the README and doc set.

**Environment note:** this project was built in a sandbox with no AWS credentials, no root access, and a restricted network allowlist (couldn't even install the `terraform` binary — HashiCorp's release server is blocked). So the plan for this build is: write and hand-review every piece of Terraform/Kubernetes/ArgoCD/Helm config carefully, validate what can be validated without cloud access (YAML syntax), and be explicit in this log about which steps are "written" vs. "actually run against AWS" — the latter needs a real AWS account and is left for a follow-up session with proper credentials.

## Day 2

Wrote terraform/bootstrap: an S3 bucket for remote state (versioning, AES256 SSE, public access fully blocked, `prevent_destroy` lifecycle guard) and a DynamoDB table for state locking (PAY_PER_REQUEST billing so it costs ~nothing when idle). This bootstrap config deliberately keeps its own state local -- there's nowhere else for it to live before this step runs. Documented the cost-control habit in docs/cost-notes.md. Could not run `terraform init`/`validate` for real -- no terraform binary available in this sandbox (no root to install it, and HashiCorp's release server is blocked by the network allowlist) -- so this was hand-reviewed for HCL correctness instead of tool-validated. Run `terraform validate` yourself before applying.
