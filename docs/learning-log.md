# Learning Log

## Day 1

Started AutoGitOps Platform to learn how Kubernetes platforms are built and operated on AWS: Terraform, EKS, GitOps with ArgoCD, and observability with Prometheus/Grafana. This project is deliberately kept separate from AutoSecureOps (Project 1) — that one proves DevSecOps around an application, this one proves the ability to build the platform such an application runs on.

Scaffolded the repo structure (terraform/{bootstrap,environments/dev,modules}, apps/, argocd/, monitoring/, tests/, docs/) and wrote the first pass of the README and doc set.

**Environment note:** this project was built in a sandbox with no AWS credentials, no root access, and a restricted network allowlist (couldn't even install the `terraform` binary — HashiCorp's release server is blocked). So the plan for this build is: write and hand-review every piece of Terraform/Kubernetes/ArgoCD/Helm config carefully, validate what can be validated without cloud access (YAML syntax), and be explicit in this log about which steps are "written" vs. "actually run against AWS" — the latter needs a real AWS account and is left for a follow-up session with proper credentials.

## Day 2

Wrote terraform/bootstrap: an S3 bucket for remote state (versioning, AES256 SSE, public access fully blocked, `prevent_destroy` lifecycle guard) and a DynamoDB table for state locking (PAY_PER_REQUEST billing so it costs ~nothing when idle). This bootstrap config deliberately keeps its own state local -- there's nowhere else for it to live before this step runs. Documented the cost-control habit in docs/cost-notes.md. Could not run `terraform init`/`validate` for real -- no terraform binary available in this sandbox (no root to install it, and HashiCorp's release server is blocked by the network allowlist) -- so this was hand-reviewed for HCL correctness instead of tool-validated. Run `terraform validate` yourself before applying.

## Day 3

Built the VPC Terraform module: one VPC, 2 AZs, 2 public + 2 private subnets, an Internet Gateway, public route table, and NAT Gateway(s) for private-subnet egress. Made NAT Gateway count configurable (`single_nat_gateway`, defaults to `true`) specifically to control cost -- one shared NAT Gateway instead of one per AZ, since this is a learning platform, not a resilience-tested production one (noted as a documented tradeoff, not an oversight). Tagged public/private subnets with the `kubernetes.io/cluster/<name>` and `kubernetes.io/role/*` tags EKS and the AWS Load Balancer Controller expect for auto-discovery.

Wired `terraform/environments/dev` to call the vpc module, with backend.tf left as an empty `s3` block (values passed via `-backend-config` at `terraform init` time rather than committed). Added tests/terraform/validate.sh (`terraform fmt -check` + `terraform init -backend=false` + `terraform validate` -- safe to run without AWS credentials).

Still no terraform binary in this sandbox to actually run that script -- hand-reviewed the HCL instead (brace balance, resource references, ternary syntax for the conditional NAT gateway). Run `tests/terraform/validate.sh` yourself before the first real `terraform plan`.

## Day 4

Built the IAM module (cluster role + node role, with the standard AmazonEKSClusterPolicy / AmazonEKSWorkerNodePolicy / AmazonEKS_CNI_Policy / AmazonEC2ContainerRegistryReadOnly attachments) and the EKS module (cluster, managed node group with `ignore_changes` on desired_size so Terraform doesn't fight Kubernetes-side autoscaling, an OIDC provider for future IRSA use, and the vpc-cni/coredns/kube-proxy add-ons). Wired both into environments/dev/main.tf alongside the vpc module.

Caught and fixed two real Terraform correctness bugs while hand-reviewing (still no terraform binary available to validate for real):
1. An invalid `depends_on = [var.cluster_role_arn]` on the EKS cluster resource -- `depends_on` can only reference resources/modules/data sources, not variables. Removed it; the implicit dependency through `role_arn = var.cluster_role_arn` already orders this correctly once the root module wires `module.iam.cluster_role_arn` in.
2. Missing `required_providers` blocks in the vpc, iam, and eks modules (eks additionally needs the `tls` provider for the OIDC thumbprint lookup) -- added them to all three.

Ran a brace/paren/bracket balance check across every .tf file as a lightweight sanity check in place of `terraform validate`. All balanced. Still strongly recommend running `tests/terraform/validate.sh` for real once you have Terraform installed locally -- a balance check catches typos, not semantic errors (wrong attribute names, type mismatches, etc.).

## Day 5

Wrote out the full deployment runbook for the first real `terraform apply` -- bootstrap first (creates remote state), then the dev environment with explicit `-backend-config` flags (kept out of the committed backend.tf so no real bucket name is hardcoded in git), then `aws eks update-kubeconfig` and verification with `kubectl get nodes` / `kubectl get pods -A`, ending with `terraform destroy`. Added docs/screenshots/README.md listing all the evidence screenshots this project will eventually need.

**Not executed** -- no AWS account access in this build environment. This is the first day where "learning goal: provision the cluster and connect to it" genuinely cannot be completed without real AWS credentials; everything here is the runbook, ready to follow, not a report of having done it. The platform-design.md EKS section is explicitly marked to be filled in with real observations after the first apply.
