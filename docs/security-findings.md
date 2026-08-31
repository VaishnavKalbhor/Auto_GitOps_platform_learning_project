# Security Findings

Security-relevant decisions and issues found while building this platform,
documented the way a real platform review would: what the risk is, what was
done about it, and what's left as a known, accepted tradeoff for a learning
project.

## Finding 1: Public EKS API endpoint

**Location:** `terraform/modules/eks/variables.tf` --
`endpoint_public_access` defaults to `true`.

### Risk

The EKS control plane's Kubernetes API server is reachable from the public
internet (though still gated by IAM authentication + Kubernetes RBAC, not
open access). A production platform's attack surface is smaller with the
endpoint private-only, reachable through a VPN, bastion, or Cloud9-in-VPC
instead.

### Remediation

Not changed in this build -- the tradeoff is deliberate and documented
rather than accidental. A public endpoint is what makes `kubectl` and
`argocd` work directly from a laptop without extra VPN infrastructure, which
matters for a project meant to be spun up, tested, and torn down repeatedly
in short sessions (see docs/cost-notes.md). `endpoint_private_access` is
also `true`, so traffic that originates inside the VPC does not need to
leave it.

**Future improvement:** set `endpoint_public_access = false` and add a
small bastion host or SSM Session Manager tunnel for `kubectl` access, or
restrict `endpoint_public_access` to specific CIDR blocks via
`public_access_cidrs` rather than allowing all of `0.0.0.0/0`.

## Finding 2: Grafana admin password pattern

**Location:** `monitoring/kube-prometheus-values.yaml`

### Risk

The first draft of this values file set `grafana.adminPassword` directly in
the file, with a placeholder value and a comment saying to override it at
install time. Even as an obviously-fake placeholder, this establishes the
habit of putting a password *field* in a file meant to be committed to Git
-- one careless `--set` skip, or one real value pasted in during a rushed
demo, and a real credential ships to the repo.

### Remediation

Changed to `grafana.admin.existingSecret`, referencing a Kubernetes Secret
(`grafana-admin-credentials`) created out-of-band with `kubectl create
secret` before the Helm chart is installed (see
monitoring/grafana-dashboard-notes.md for the exact command, which generates
a random password with `openssl rand` rather than asking for one to be typed
in). No password-shaped field exists anywhere in this repo's committed YAML
now.

### Learning

This is the same class of issue Gitleaks is meant to catch in
`.github/workflows/platform-security.yml` -- but a placeholder value like
`"changeme-set-a-real-value"` doesn't look like a real secret and wouldn't
have been flagged by a pattern-matching scanner. The fix here didn't come
from a tool; it came from noticing the shape of the problem while writing
the values file. Tools catch real secrets that slip in; they don't catch a
file *designed* to eventually hold one.

## Finding 3: Kubernetes workload hardening

**Location:** `apps/vehicle-telemetry-demo/deployment.yaml`

### Risk

Containers running with default settings can run as root, escalate
privileges, and hold unnecessary Linux capabilities -- unnecessary attack
surface for a workload that doesn't need any of that.

### Remediation

Applied from the start rather than found and fixed after the fact: resource
requests/limits, readiness/liveness probes, and a `securityContext` with
`runAsNonRoot: true`, `allowPrivilegeEscalation: false`, and all Linux
capabilities dropped. `.github/workflows/platform-security.yml` runs
`kube-score` against the rendered manifests to catch regressions on this
going forward.

## Finding 4: Worker node IAM uses broad AWS-managed policies

**Location:** `terraform/modules/iam/main.tf`

### Risk

`AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, and
`AmazonEC2ContainerRegistryReadOnly` are broad, AWS-managed policies rather
than a minimal custom policy scoped to exactly what this project's node
group needs. This is standard practice (it's what AWS's own EKS
getting-started docs recommend) but is not least-privilege in the strict
sense.

### Remediation

Accepted as-is for this project -- writing and maintaining a custom
least-privilege policy for EKS worker nodes is a meaningful undertaking on
its own, and these are the same managed policies most real EKS deployments
use. Flagged here rather than silently accepted so it reads as a conscious
scope decision, not an oversight. **Future improvement:** IRSA (IAM Roles
for Service Accounts) is already partially set up -- the OIDC provider
exists (`terraform/modules/eks/main.tf`) -- so any add-on that needs its own
AWS permissions (AWS Load Balancer Controller, External Secrets, etc.)
should get a scoped IRSA role rather than broader node-level permissions.

## Finding 5: Terraform state bucket hardening

**Location:** `terraform/bootstrap/s3-backend.tf`

Not a finding against something wrong -- documenting what was done
correctly and why, since a reviewer will look for this: versioning enabled
(state history/recovery), AES256 server-side encryption, all four S3 public
access block settings enabled, and a `prevent_destroy` lifecycle guard so
`terraform destroy` in the bootstrap directory can't accidentally delete the
bucket every environment's state depends on. The DynamoDB lock table does
*not* have the same guard -- losing it just means the next `terraform init`
recreates it, so the extra protection isn't worth the friction there.
