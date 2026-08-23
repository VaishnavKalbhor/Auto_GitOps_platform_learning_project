# GitOps Workflow

*(Planned test described below is not yet run for real -- see docs/learning-log.md.)*

The application is not deployed manually using `kubectl apply` during normal
operation. Instead, the desired Kubernetes state is stored in Git
(`apps/vehicle-telemetry-demo/`, referenced by
`argocd/applications/vehicle-telemetry-app.yaml`). ArgoCD watches the
repository and reconciles the cluster to match the committed manifests.

## App-of-apps

`argocd/app-of-apps.yaml` is the one manifest actually applied by hand
(`kubectl apply -f argocd/app-of-apps.yaml -n argocd`). It points at
`argocd/applications/`, so ArgoCD picks up every `Application` in that
directory -- `vehicle-telemetry-app.yaml` and `monitoring-app.yaml` -- without
either of them needing a manual `kubectl apply`.

## Planned test

1. Change `replicas: 2` to `replicas: 3` in
   `apps/vehicle-telemetry-demo/deployment.yaml`.
2. Commit and push to `main`.
3. Watch ArgoCD detect the drift and sync:
   ```bash
   kubectl get deployment vehicle-telemetry-demo -n vehicle-demo -w
   argocd app get vehicle-telemetry-demo
   ```
4. Confirm the deployment reaches 3/3 ready replicas without any manual
   `kubectl apply`.
5. Screenshot `docs/screenshots/argocd-app-synced.png` and
   `docs/screenshots/replica-change-synced.png`.

## Multi-source Applications

`monitoring-app.yaml` uses ArgoCD's multi-source Application feature: the
Helm chart comes from the `prometheus-community` Helm repo, while its values
file (`monitoring/kube-prometheus-values.yaml`) is pulled from this Git repo
via a `ref: values` source. This keeps the values file reviewable in normal
pull requests instead of being inlined into the Application manifest.
