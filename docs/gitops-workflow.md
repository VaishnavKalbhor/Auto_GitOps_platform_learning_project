# GitOps Workflow

*(To be filled in with real evidence once ArgoCD is installed and a sync has actually been observed — see Day 8/9 in the learning log.)*

The application is not deployed manually using `kubectl apply` during normal operation. Instead, the desired Kubernetes state is stored in Git (`apps/vehicle-telemetry-demo/`, referenced by `argocd/applications/vehicle-telemetry-app.yaml`). ArgoCD watches the repository and reconciles the cluster to match the committed manifests.

## Planned test

Change the replica count in Git from 2 to 3, push, and confirm ArgoCD detects the drift and syncs the deployment without any manual `kubectl` command.
