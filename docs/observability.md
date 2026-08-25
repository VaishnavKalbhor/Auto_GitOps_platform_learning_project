# Observability

*(To be filled in with real screenshots once kube-prometheus-stack is
installed -- see docs/learning-log.md and monitoring/grafana-dashboard-notes.md.)*

## Stack

Monitoring is `kube-prometheus-stack` (Prometheus + Grafana + Alertmanager +
kube-state-metrics + node-exporter), deployed via the `monitoring` ArgoCD
Application (`argocd/applications/monitoring-app.yaml`), configured by
`monitoring/kube-prometheus-values.yaml`.

## What's being monitored

- Cluster CPU/memory usage
- Pod status and restarts
- Deployment replica counts (ties into the HPA test)
- Node readiness
- HPA scaling events

A supplementary `PrometheusRule` (`monitoring/alert-rules.yaml`) adds three
alerts specific to the demo app: zero available replicas, frequent restarts
(possible crash loop), and the HPA sitting at its max replica ceiling under
sustained load.

## Deliberate scope cuts

- No persistent storage for Prometheus (`retention: 6h`, no PVC) -- this
  cluster is destroyed after every session (see cost-notes.md), so
  durable metrics storage would be wasted effort.
- `kubeEtcd`/`kubeScheduler`/`kubeControllerManager` scraping disabled --
  those aren't exposed on a managed EKS control plane, AWS owns them.
- Grafana and Prometheus are reached via `kubectl port-forward`, not a
  public Ingress/LoadBalancer -- same reasoning as the ArgoCD UI.

See monitoring/grafana-dashboard-notes.md for the exact install and
port-forward commands, and which default dashboards to check.
