# AutoGitOps Platform

A GitOps-driven Kubernetes platform on AWS using Terraform, EKS, ArgoCD, and Prometheus/Grafana.

![Terraform Checks](https://github.com/<your-github-username>/autogitops-platform/actions/workflows/terraform-checks.yml/badge.svg)
![K8s Manifest Checks](https://github.com/<your-github-username>/autogitops-platform/actions/workflows/k8s-manifest-checks.yml/badge.svg)

## Overview

This project provisions an AWS EKS platform using Terraform and deploys
workloads using ArgoCD GitOps. It adds observability with Prometheus/Grafana
and validates Kubernetes self-healing and autoscaling behavior.

This project is deliberately separate from
[AutoSecureOps](../autosecureops): that one proves DevSecOps practice around
an application; this one proves the ability to build the **platform** such
applications run on.

## Automotive Context

Modern automotive software platforms rely on cloud-connected services for
telemetry, diagnostics, OTA workflows, fleet monitoring, and customer-facing
digital services. This project simulates the platform layer required to
deploy and operate such services securely and reliably on Kubernetes --
`vehicle-telemetry-demo` stands in for the kind of workload a real
connected-vehicle backend would run.

## Cost Warning

This project provisions real, billed AWS resources (EKS control plane, NAT
Gateway, EC2 worker nodes). **Set an AWS Budget alarm before running
`terraform apply`.** See [docs/cost-notes.md](docs/cost-notes.md). The habit
throughout: `terraform apply` -> test and screenshot -> `terraform destroy`.
Never leave the cluster running between sessions.

**Want to see/demo most of this without any AWS cost?** See
[local/README.md](local/README.md) -- ArgoCD, GitOps sync, Prometheus/Grafana,
HPA autoscaling, and pod self-healing all run for real against a free local
`kind` cluster. Only the Terraform/EKS provisioning layer needs a real AWS
account.

## Architecture

See [docs/architecture.md](docs/architecture.md) for the full breakdown.

## Tech Stack

- AWS EKS
- Terraform
- Amazon VPC
- IAM (incl. OIDC/IRSA-ready)
- S3 remote state + DynamoDB locking
- Kubernetes
- ArgoCD (app-of-apps pattern)
- Helm
- Prometheus / Grafana / Alertmanager
- GitHub Actions
- Checkov, kube-score, Gitleaks

## What I Built

- Terraform modules for VPC, IAM, and EKS, composed in `terraform/environments/dev`
- Remote state backend using S3 + DynamoDB locking
- EKS cluster module with a managed node group
- ArgoCD app-of-apps GitOps deployment pattern
- Demo vehicle telemetry application (Deployment, Service, HPA, kustomization)
- Prometheus/Grafana monitoring stack config, with a project-specific alert rule set
- HPA autoscaling test scripts
- Pod self-healing / node drain test scripts
- CI validation for Terraform and Kubernetes manifests (fmt/validate/Checkov/kube-score/Gitleaks/kubeconform)

## Validation

**Honest status, not aspirational:** this repository was built without AWS
credentials available in the build environment (see
[docs/learning-log.md](docs/learning-log.md) for the day-by-day detail of
what that meant). Every piece of code below was written and hand/tool-reviewed
as carefully as possible without a live AWS account, Terraform binary,
kubectl, or Helm available. The "Provable locally?" column shows which parts
can be validated for real, right now, at zero cost via `local/` -- see
[local/README.md](local/README.md) for the honest breakdown of what a local
`kind` cluster does and doesn't prove.

| Test | Status | Provable locally (kind), no AWS cost? |
|---|---|---|
| Terraform fmt/validate | Not yet run (no terraform binary in the build environment; will run on first CI push) | No -- AWS-specific |
| Checkov / kube-score / Gitleaks | Not yet run (same reason; wired into `.github/workflows/platform-security.yml`) | Partially -- kube-score/Gitleaks yes, Checkov (Terraform) no |
| EKS cluster provisioning | Not yet run -- runbook in docs/platform-design.md | No -- AWS-specific |
| ArgoCD install + sync | Not yet run -- runbook in argocd/install.md, docs/gitops-workflow.md | **Yes** -- see local/README.md |
| Demo app deployment | Not yet run | **Yes** |
| Prometheus/Grafana install | Not yet run -- runbook in monitoring/grafana-dashboard-notes.md | **Yes** |
| HPA scaling | Not yet run -- runbook in docs/autoscaling-and-self-healing.md | **Yes** (after patching metrics-server, see local/bootstrap-local.sh) |
| Pod self-healing | Not yet run -- runbook in docs/autoscaling-and-self-healing.md | **Yes** |
| `terraform destroy` | Not yet run | No -- AWS-specific |

Two real bugs were still found and fixed purely through hand-review during
this build (documented in docs/learning-log.md Day 4 and Day 9): an invalid
`depends_on` referencing a Terraform variable instead of a resource, and an
ArgoCD `Application` manifest illegally setting both `source` and `sources`.
Also see [docs/security-findings.md](docs/security-findings.md) for a
Grafana credentials issue found and fixed before anything was ever applied.

## Limitations

- Built for learning, not production
- Single dev environment, single region, two AZs
- Public EKS API endpoint (documented tradeoff, see security-findings.md)
- Broad AWS-managed IAM policies rather than custom least-privilege policies
- No production-grade secrets manager integration (Kubernetes Secrets only)
- Cluster is meant to be destroyed after each testing session to control cost
- **Nothing in this repo has been run against real AWS yet** -- see Validation above

## Documentation

- [Architecture](docs/architecture.md)
- [Platform Design](docs/platform-design.md) (includes the deployment runbook)
- [GitOps Workflow](docs/gitops-workflow.md)
- [Observability](docs/observability.md)
- [Autoscaling and Self-Healing](docs/autoscaling-and-self-healing.md)
- [Security Findings](docs/security-findings.md)
- [Cost Notes](docs/cost-notes.md)
- [Learning Log](docs/learning-log.md)

## Screenshots

See [docs/screenshots/README.md](docs/screenshots/README.md) for the full
list of evidence screenshots this project needs -- none exist yet, since
nothing has been run against real AWS in this build.
