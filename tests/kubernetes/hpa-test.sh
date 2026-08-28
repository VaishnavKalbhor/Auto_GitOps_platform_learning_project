#!/bin/bash
# Watches HPA and pod scaling behavior. Run tests/load/generate-load.sh
# first (in another terminal) to actually create the CPU load this depends
# on to see scaling happen.
#
# Prerequisite: metrics-server must be running in the cluster, or the HPA
# will show <unknown> for its current CPU metric and never scale. EKS does
# not install metrics-server by default -- add it once, before this test:
#   aws eks create-addon --cluster-name autogitops-dev --addon-name metrics-server
set -e

echo "--- metrics-server check ---"
kubectl get deployment metrics-server -n kube-system || {
  echo "metrics-server not found -- HPA will not be able to scale. See the comment at the top of this script."
  exit 1
}

echo "--- Current HPA state ---"
kubectl get hpa -n vehicle-demo

echo "--- Current pod resource usage ---"
kubectl top pods -n vehicle-demo || echo "(kubectl top requires metrics-server to have collected at least one sample -- try again in ~1 minute if this is empty)"

echo "--- Watching deployment (Ctrl+C to stop watching) ---"
kubectl get deployment vehicle-telemetry-demo -n vehicle-demo -w
