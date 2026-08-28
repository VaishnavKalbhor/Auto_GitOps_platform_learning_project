#!/bin/bash
# Validates Kubernetes self-healing: deletes a running pod and confirms the
# Deployment controller replaces it. Optionally also cordons/drains a node
# to show pod rescheduling. See docs/autoscaling-and-self-healing.md for the
# full writeup and what to screenshot.
set -e

NAMESPACE="vehicle-demo"
DEPLOYMENT="vehicle-telemetry-demo"

echo "=== Pod failure test ==="
echo "--- Pods before ---"
kubectl get pods -n "$NAMESPACE" -l app="$DEPLOYMENT"

TARGET_POD=$(kubectl get pods -n "$NAMESPACE" -l app="$DEPLOYMENT" -o jsonpath='{.items[0].metadata.name}')
if [ -z "$TARGET_POD" ]; then
  echo "No pods found for app=$DEPLOYMENT in namespace $NAMESPACE -- is the app deployed?"
  exit 1
fi

echo "Deleting pod: $TARGET_POD"
kubectl delete pod "$TARGET_POD" -n "$NAMESPACE"

echo "--- Pods after (watching for the replacement to become Ready; Ctrl+C once it is) ---"
kubectl get pods -n "$NAMESPACE" -l app="$DEPLOYMENT" -w &
WATCH_PID=$!
sleep 30
kill "$WATCH_PID" 2>/dev/null || true

echo ""
echo "=== Optional: node cordon/drain test ==="
echo "Not run automatically by this script -- do this manually and deliberately:"
echo ""
echo "  kubectl get nodes"
echo "  kubectl cordon <node-name>"
echo "  kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data"
echo "  kubectl get pods -A -o wide"
echo "  kubectl uncordon <node-name>   # when done, unless this is the last test of the session"
echo ""
echo "Failure test complete. Update docs/autoscaling-and-self-healing.md with what you observed."
