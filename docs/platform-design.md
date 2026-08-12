# Platform Design

## Why Terraform

Infrastructure as code makes the platform reproducible and destroyable on demand — important both as an engineering practice and, for this project specifically, as a cost-control mechanism (see [cost-notes.md](cost-notes.md)).

## Why EKS

Amazon EKS is a managed Kubernetes control plane. It removes the operational burden of running `etcd`/API servers yourself, while still requiring the platform engineer to reason about networking (VPC/subnets), identity (IAM roles for the cluster and nodes), and compute (managed node groups). Building this from scratch — rather than clicking through the AWS console — is what demonstrates the skill.

## EKS Platform (to be filled in after a real `terraform apply`)

This section is written in advance of running the infrastructure for real. Once `terraform apply` succeeds and `kubectl get nodes` / `kubectl get pods -A` have been run and screenshotted, this section should be updated with what was actually observed (node count, instance types seen, any surprises).

Expected shape: the platform uses Amazon EKS as the managed Kubernetes control plane. Worker nodes come from an EKS managed node group (t3.small/t3.medium, 1-3 nodes). Terraform provisions the AWS networking, IAM roles, and EKS resources — proving that a Kubernetes platform is not just the cluster itself, but also networking, identity, permissions, and compute capacity.

## Limitations (by design, for a learning project)

- Single `dev` environment, single region, single AZ pair.
- Public EKS API endpoint (see [security-findings.md](security-findings.md) for the documented tradeoff).
- No multi-account or multi-cluster setup.
- Node groups are small and cost-optimized, not right-sized for real workloads.
