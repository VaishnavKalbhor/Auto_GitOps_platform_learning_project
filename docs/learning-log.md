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

## Day 6

Added the vehicle-telemetry-demo Kubernetes manifests: a dedicated `vehicle-demo` namespace, a 2-replica Deployment (resource requests/limits, readiness/liveness probes, non-root securityContext), a ClusterIP Service, and an HPA (2-5 replicas, 60% CPU target), tied together with kustomization.yaml. Used `nginxinc/nginx-unprivileged` as a stand-in workload rather than a custom image -- this project is about the platform (Terraform/EKS/ArgoCD/monitoring), not the application, and using a public image avoids needing a container registry just to demonstrate autoscaling and self-healing. Documented in the deployment.yaml comments that this is swappable for a real service later (e.g. the telemetry-service from the AutoSecureOps project).

Noted for later: the HPA needs the `metrics-server` add-on running in-cluster to read CPU utilization -- EKS doesn't install it by default. Need to add `aws eks create-addon --addon-name metrics-server ...` (or a Helm install) to the Day 11 HPA test runbook.

All 5 YAML files validated with PyYAML. Added tests/kubernetes/smoke-test.sh.

## Day 7

Added .github/workflows/terraform-checks.yml (fmt/init -backend=false/validate across both terraform/bootstrap and terraform/environments/dev via a matrix, plus a Checkov IaC scan with soft_fail so it reports without blocking yet -- tightened later once findings are triaged) and k8s-manifest-checks.yml (yamllint across apps/argocd/monitoring, plus kubeconform schema validation against the kustomize-rendered demo app manifests). This is the first point where the Terraform code actually gets validated by a real `terraform validate` -- since this sandbox has no terraform binary, the first real validation of everything built on Days 2-5 will happen on the first GitHub Actions run of this workflow, not before. Worth watching that first run closely.

## Day 8

Documented the ArgoCD install procedure in argocd/install.md: create the namespace, apply the stock install manifest, port-forward the API server, and pull the initial admin password from the generated secret. Explained what each ArgoCD component does (server/repo-server/application-controller/dex/redis) since "just apply this YAML" without understanding the pieces isn't the point of the project.

Not executed -- no live cluster to install ArgoCD onto in this build. This is the runbook to follow once Day 5's cluster is actually up.

## Day 9

Added the ArgoCD Application manifests: vehicle-telemetry-app.yaml (points at apps/vehicle-telemetry-demo, auto-sync + self-heal + CreateNamespace), monitoring-app.yaml (kube-prometheus-stack from its Helm repo), and app-of-apps.yaml (the one manifest you actually `kubectl apply` by hand -- it bootstraps both child Applications from argocd/applications/).

Caught a real bug while reviewing monitoring-app.yaml against the ArgoCD Application CRD from memory: I'd initially written both `spec.source` (singular) and `spec.sources` (the multi-source list) on the same Application, which ArgoCD rejects outright ("cannot use both source and sources fields"). Needed `sources` (plural) here specifically because the Helm chart comes from the prometheus-community Helm repo while its values file comes from this Git repo -- that's exactly what multi-source Applications are for. Fixed by removing the singular `source` block.

Updated docs/gitops-workflow.md with the app-of-apps explanation and the planned replica-count drift test. All 3 ArgoCD YAML files validated with PyYAML. Still unexecuted against a real ArgoCD instance.

## Day 10

Added monitoring/kube-prometheus-values.yaml (Prometheus/Alertmanager/Grafana resource requests sized for a small t3.small node group, 6h retention with no PVC since the cluster is destroyed after each session anyway, control-plane scraping disabled since EKS doesn't expose etcd/scheduler/controller-manager), monitoring/alert-rules.yaml (a PrometheusRule with 3 alerts scoped to the demo app: zero-replica, high-restart-rate, HPA-maxed-out), and monitoring/grafana-dashboard-notes.md with install/port-forward/dashboard-navigation instructions. Updated docs/observability.md to explain the deliberate scope cuts rather than just listing what's there.

Not installed against a real cluster -- helm binary isn't available in this sandbox either (same restriction as terraform/kubectl). YAML validated with PyYAML; the Helm values schema itself (are these the right keys for kube-prometheus-stack's current chart version?) can only really be confirmed with a real `helm install --dry-run` or `helm template` against the actual chart, which needs network access this sandbox doesn't have to Helm repos either.

## Day 11

Added tests/load/generate-load.sh (a busybox pod looping wget against the demo service's ClusterIP DNS name) and tests/kubernetes/hpa-test.sh (checks metrics-server is present first -- since without it the HPA just shows `<unknown>` and never scales -- then watches `kubectl get hpa` and the deployment). Wrote out the full HPA test procedure and a results table (left blank, to fill in with real numbers) in docs/autoscaling-and-self-healing.md.

Explicitly called out the metrics-server prerequisite (`aws eks create-addon --addon-name metrics-server`) since EKS doesn't install it by default -- this was flagged as a to-do back on Day 6 when the HPA manifest was written, and now the runbook actually handles it instead of leaving it as a surprise mid-test.

Not run against a real cluster.

## Day 12

Added tests/kubernetes/failure-test.sh -- automates the pod-delete half of the self-healing test (finds a running vehicle-telemetry-demo pod via label selector, deletes it, watches for 30s as the replacement comes up) and prints the node cordon/drain commands as a manual follow-on step (deliberately not automated -- draining a node is disruptive enough that it should be a conscious action, not something a script does unattended). The narrative/results writeup for this test already lives in docs/autoscaling-and-self-healing.md (written on Day 11 alongside the HPA test, since both are "prove the platform does the thing it claims to do" tests and read better together than split across two docs).

Not run against a real cluster.
