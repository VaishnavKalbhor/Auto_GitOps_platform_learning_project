# Local Demo (No AWS Cost)

Everything in this platform that lives *above* Kubernetes -- ArgoCD, GitOps
sync, Prometheus/Grafana, HPA autoscaling, pod self-healing -- doesn't care
whether the cluster is EKS or a free local one. This directory runs the same
manifests (`apps/`, `argocd/`, `monitoring/`, the `tests/kubernetes` and
`tests/load` scripts) against a local [kind](https://kind.sigs.k8s.io/)
cluster instead, at zero cost.

## What this genuinely proves vs. what it doesn't

| Layer | Provable locally? |
|---|---|
| ArgoCD install + GitOps reconciliation | **Yes, for real.** ArgoCD really clones this repo, really syncs, really self-heals drift. |
| Prometheus/Grafana monitoring | **Yes, for real.** Real scraping, real dashboards, real alerts. |
| HPA autoscaling | **Yes, for real**, once metrics-server is patched for kind (the bootstrap script does this). |
| Pod self-healing / node drain | **Yes, for real.** Deployment controller behavior is identical to EKS. |
| Terraform: VPC, IAM, EKS cluster/node group provisioning | **No.** kind runs as Docker containers on one machine -- there's no real cloud networking, no IAM, no managed control plane, no multi-AZ story. That part of the project is still "written and reviewed, runbook-only" (see the main README's Validation table) until it's actually run against AWS. |
| Realistic node failure (EC2 instance termination) | No -- kind nodes are containers, not EC2 instances. |

Be honest about this split when presenting the project: "the GitOps,
monitoring, and resilience layers are validated locally against a free kind
cluster; the Terraform/AWS provisioning layer is written and reviewed but
run only when actually needed, to control cost" is a completely normal,
respected thing to say to a recruiter or interviewer -- it shows you
understand the cost tradeoff, which is itself part of the platform
engineering skill being demonstrated.

## Prerequisites

Install on your own machine (none of this runs inside the Claude sandbox
this repo was originally built in):

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (running)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- `kubectl`
- `helm`

## Usage

```bash
cd local
./bootstrap-local.sh https://github.com/<your-username>/autogitops-platform.git
```

(Must be pushed to GitHub first -- ArgoCD needs a real Git URL it can clone,
not a local path.)

Then follow the printed instructions to open ArgoCD and Grafana, watch
`kubectl get applications -n argocd -w` until both `vehicle-telemetry-demo`
and `monitoring` show `Synced`/`Healthy`, and run the existing test scripts
against this cluster exactly as written for EKS:

```bash
cd ../tests/kubernetes && ./smoke-test.sh
cd ../load && ./generate-load.sh        # separate terminal
cd ../kubernetes && ./hpa-test.sh       # watch it scale
./failure-test.sh                       # pod self-healing
```

Take the same screenshots listed in `docs/screenshots/README.md` -- they're
just as real here as they'd be against EKS, for everything except the
AWS-provisioning-specific ones (`terraform-apply-success.png`, `eks-nodes.png`,
`terraform-destroy-success.png`).

## Teardown

```bash
./teardown-local.sh
```

Costs nothing to leave running either way (it's local Docker, not billed AWS
resources) but no reason not to clean it up.
