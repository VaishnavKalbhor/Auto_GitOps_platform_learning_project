#!/bin/bash
# Basic smoke test: confirms the cluster is reachable and the demo app is
# actually running. Run this after kubectl is pointed at the cluster
# (aws eks update-kubeconfig ...).
set -e

echo "--- Nodes ---"
kubectl get nodes

echo "--- All pods ---"
kubectl get pods -A

echo "--- vehicle-telemetry-demo deployment ---"
kubectl get deployment vehicle-telemetry-demo -n vehicle-demo

echo "--- vehicle-telemetry-demo service ---"
kubectl get svc vehicle-telemetry-demo -n vehicle-demo

echo "--- vehicle-telemetry-demo pods ---"
kubectl get pods -n vehicle-demo -o wide

echo "Smoke test complete."
