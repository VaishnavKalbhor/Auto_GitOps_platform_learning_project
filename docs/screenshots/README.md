# Screenshots

Evidence screenshots referenced throughout the docs. None of these exist yet
in this build -- this repo was written without AWS credentials available, so
nothing has been provisioned or run for real. Capture these once you actually
run each step against your own AWS account (see docs/learning-log.md for
exactly what's code-only vs. run):

- terraform-apply-success.png -- `terraform apply` completing for environments/dev
- eks-nodes.png -- `kubectl get nodes` showing Ready worker nodes
- kube-system-pods.png -- `kubectl get pods -A` (or -n kube-system)
- argocd-pods-running.png -- `kubectl get pods -n argocd`
- argocd-app-synced.png -- `argocd app get vehicle-telemetry-demo` (or the UI) showing Synced/Healthy
- replica-change-synced.png -- before/after of the Git replica-count test syncing
- prometheus-targets.png -- Prometheus targets page, all up
- grafana-cluster-dashboard.png -- Grafana cluster overview dashboard
- grafana-pod-dashboard.png -- Grafana per-pod dashboard
- hpa-before-load.png / hpa-after-load.png -- `kubectl get hpa -n vehicle-demo` before and during load
- pods-scaled.png -- `kubectl get pods -n vehicle-demo` showing more replicas under load
- pod-before-delete.png / pod-recreated.png -- self-healing test
- node-cordon-test.png -- cordon/drain test
- terraform-destroy-success.png -- `terraform destroy` completing (the most important one for cost discipline)
