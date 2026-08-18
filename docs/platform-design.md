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

## Deployment Runbook (first real `terraform apply`)

Run this from a machine with the AWS CLI configured (`aws configure` or SSO),
Terraform installed, and **an AWS Budget alarm already set** (see
[cost-notes.md](cost-notes.md)).

```bash
# 1. One-time bootstrap (creates the S3 state bucket + DynamoDB lock table)
cd terraform/bootstrap
terraform init
terraform fmt -check
terraform validate
terraform plan -var="state_bucket_name=autogitops-terraform-state-<yourname>"
terraform apply -var="state_bucket_name=autogitops-terraform-state-<yourname>"

# 2. Point the dev environment at that remote state
cd ../environments/dev
terraform init \
  -backend-config="bucket=autogitops-terraform-state-<yourname>" \
  -backend-config="key=environments/dev/terraform.tfstate" \
  -backend-config="region=eu-central-1" \
  -backend-config="dynamodb_table=autogitops-terraform-locks" \
  -backend-config="encrypt=true"

terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Expect the `terraform apply` for the dev environment to take **15-20 minutes**
(EKS control plane provisioning is the slow part). Take a screenshot of the
successful apply output (`docs/screenshots/terraform-apply-success.png`).

```bash
# 3. Connect kubectl to the new cluster
aws eks update-kubeconfig --region eu-central-1 --name autogitops-dev

# 4. Verify
kubectl get nodes
kubectl get pods -A
```

Screenshot `docs/screenshots/eks-nodes.png` and
`docs/screenshots/kube-system-pods.png`, then update the "EKS Platform"
section above with what was actually observed (node count, any add-on pods
that took a while to become Ready, anything that surprised you).

```bash
# 5. Tear down when done testing for this session
cd ../../environments/dev
terraform destroy
```

Screenshot `docs/screenshots/terraform-destroy-success.png`. Do not skip this
step between sessions -- see [cost-notes.md](cost-notes.md).

