#!/bin/bash
# Stands up the free, local version of AutoGitOps Platform on kind:
#   kind cluster -> metrics-server -> ArgoCD -> app-of-apps (demo app +
#   monitoring). Everything downstream of "you have a working kubectl
#   context" is real here -- ArgoCD really syncs from Git, Prometheus really
#   scrapes, the HPA really scales. What's NOT real: any of the Terraform/
#   VPC/IAM/EKS work -- kind is a single-machine Docker-based cluster, not
#   AWS. See local/README.md for exactly what this does and doesn't prove.
#
# Prerequisites: Docker Desktop running, kind, kubectl, helm all installed
# and on PATH.
#
# Usage:
#   ./bootstrap-local.sh <your-git-repo-url>
# Example:
#   ./bootstrap-local.sh https://github.com/yourname/autogitops-platform.git

set -e

REPO_URL="$1"
CLUSTER_NAME="autogitops-local"

if [ -z "$REPO_URL" ]; then
  echo "Usage: $0 <your-git-repo-url>"
  echo "  (must be a URL ArgoCD can clone -- i.e. actually pushed to GitHub, not a local path)"
  exit 1
fi

for cmd in docker kind kubectl helm; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required tool: $cmd. Install it before running this script."
    exit 1
  fi
done

echo "=== 1. Create kind cluster ==="
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  echo "Cluster '$CLUSTER_NAME' already exists, reusing it."
else
  kind create cluster --config kind-config.yaml
fi
kubectl cluster-info --context "kind-$CLUSTER_NAME"

echo "=== 2. Install metrics-server (needed for HPA; kind doesn't ship it) ==="
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# kind's kubelet serving certs aren't valid for the hostname metrics-server
# expects by default -- patch it to tolerate that (fine for a local demo
# cluster, would NOT be an acceptable fix on a real production cluster).
kubectl patch deployment metrics-server -n kube-system --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl rollout status deployment metrics-server -n kube-system --timeout=120s

echo "=== 3. Install ArgoCD ==="
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "Waiting for ArgoCD to become ready (this can take a few minutes)..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n argocd

echo "=== 4. Create Grafana admin secret ==="
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic grafana-admin-credentials \
  -n monitoring \
  --from-literal=admin-user=admin \
  --from-literal=admin-password="$(openssl rand -base64 20)" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "=== 5. Point app-of-apps at your repo and apply it ==="
sed "s|https://github.com/<your-github-username>/autogitops-platform.git|$REPO_URL|" \
  ../argocd/app-of-apps.yaml | kubectl apply -n argocd -f -

echo ""
echo "=== Done ==="
echo "ArgoCD UI:  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "Grafana:    kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80"
echo "  admin password: kubectl get secret grafana-admin-credentials -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d"
echo ""
echo "ArgoCD will take a minute or two to pull this repo and sync both Applications."
echo "Watch it with: kubectl get applications -n argocd -w"
echo ""
echo "When done, tear down with: ./teardown-local.sh"
