# Architecture

## Overview

AutoGitOps Platform provisions a small but realistic AWS EKS platform and layers GitOps delivery and observability on top of it.

```
Terraform (IaC)
   |
   |-- VPC module -----------> VPC, public/private subnets, IGW, route tables, NAT
   |-- IAM module -----------> Cluster role, node role, IRSA-ready policies
   |-- EKS module -----------> EKS control plane + managed node group
   |-- observability module -> (optional) supporting AWS resources for monitoring
   v
EKS Cluster
   |
   |-- ArgoCD (installed via kubectl/Helm) --> watches this Git repo
   |     |-- apps/vehicle-telemetry-demo ----> Deployment, Service, HPA
   |     `-- monitoring-app ------------------> kube-prometheus-stack
   |
   `-- kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
```

## Environments

Only one environment is built for this learning project: `terraform/environments/dev`. It composes the `vpc`, `iam`, and `eks` modules. Production-style environments (staging/prod, multiple regions, private-only endpoints) are out of scope — see [platform-design.md](platform-design.md) for what a production version would add.

## Data flow (GitOps)

1. A change to `apps/vehicle-telemetry-demo/*` or `argocd/applications/*` is pushed to `main`.
2. ArgoCD (running in-cluster, watching this repo) detects drift between Git and the live cluster state.
3. ArgoCD reconciles the cluster to match Git — no `kubectl apply` in normal operation.
4. Prometheus scrapes the workload and cluster metrics; Grafana visualizes them.
