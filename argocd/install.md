# Installing ArgoCD

*(Runbook -- not yet executed in this build. See docs/learning-log.md.)*

Prerequisite: the EKS cluster is up and `kubectl` is pointed at it
(`aws eks update-kubeconfig --region eu-central-1 --name autogitops-dev`).

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait for everything to come up:

```bash
kubectl get pods -n argocd -w
```

Take `docs/screenshots/argocd-pods-running.png` once all pods show `Running`.

## Accessing the UI / CLI

Port-forward the API server (simplest option for a learning cluster -- a
production platform would front this with an Ingress/LoadBalancer and real
TLS):

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Get the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

Then either open https://localhost:8080 (username `admin`), or use the CLI:

```bash
argocd login localhost:8080 --username admin --password <password-from-above> --insecure
```

## What gets installed

The stock `install.yaml` deploys: `argocd-server` (API/UI), `argocd-repo-server`
(fetches and renders Git manifests), `argocd-application-controller`
(reconciliation loop), `argocd-dex-server` (SSO, unused in this project),
`argocd-redis` (caching), and the relevant CRDs (`Application`,
`AppProject`, etc.) that `argocd/applications/*.yaml` and
`argocd/app-of-apps.yaml` depend on.

## Change the admin password

The initial admin secret is meant to be rotated immediately in any
non-throwaway cluster:

```bash
argocd account update-password
```

For this short-lived learning cluster (destroyed at the end of each session,
see docs/cost-notes.md) this is optional but still good practice to actually
do once, for the habit.
