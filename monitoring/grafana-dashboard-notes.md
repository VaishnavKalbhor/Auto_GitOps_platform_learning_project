# Grafana Dashboard Notes

*(To be filled in with real panel screenshots once kube-prometheus-stack is
installed -- see docs/learning-log.md.)*

## Install

Create the Grafana admin credentials as a Secret *before* installing the
chart -- values.yaml deliberately has no password field in it (see
docs/security-findings.md, Finding 2):

```bash
kubectl create namespace monitoring

kubectl create secret generic grafana-admin-credentials \
  -n monitoring \
  --from-literal=admin-user=admin \
  --from-literal=admin-password="$(openssl rand -base64 20)"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f monitoring/kube-prometheus-values.yaml

kubectl apply -f monitoring/alert-rules.yaml
```

Retrieve the generated password later with:

```bash
kubectl get secret grafana-admin-credentials -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d
```

(In normal operation this is installed via the `monitoring` ArgoCD
Application instead of a manual `helm install` -- see
`argocd/applications/monitoring-app.yaml`. The manual command above is for
first-time testing/debugging before GitOps takes over.)

## Access

```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```

Open http://localhost:3000 (username `admin`, password as set above).

## Dashboards to check

kube-prometheus-stack ships default dashboards out of the box -- these are
the ones relevant to this project:

- **Kubernetes / Compute Resources / Cluster** -- overall CPU/memory usage
  (screenshot: `docs/screenshots/grafana-cluster-dashboard.png`)
- **Kubernetes / Compute Resources / Namespace (Pods)** -- filtered to
  `vehicle-demo`, shows per-pod CPU/memory, useful for correlating with the
  HPA test (screenshot: `docs/screenshots/grafana-pod-dashboard.png`)
- **Kubernetes / Networking / Cluster** -- pod network traffic, useful during
  the load test

## Prometheus targets

```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
```

Open http://localhost:9090/targets -- confirm every target shows `UP`,
especially `kube-state-metrics` and `node-exporter` (screenshot:
`docs/screenshots/prometheus-targets.png`).
