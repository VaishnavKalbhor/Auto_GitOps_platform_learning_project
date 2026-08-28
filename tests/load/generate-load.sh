#!/bin/bash
# Generates sustained HTTP load against vehicle-telemetry-demo from inside
# the cluster, to trigger HPA scaling. Run tests/kubernetes/hpa-test.sh in
# another terminal while this runs.
set -e

echo "Starting load generator pod (Ctrl+C here does NOT stop it -- see cleanup command below)..."
kubectl run load-generator \
  --image=busybox:1.36 \
  --restart=Never \
  -n vehicle-demo \
  -- /bin/sh -c "while true; do wget -q -O- http://vehicle-telemetry-demo.vehicle-demo.svc.cluster.local; done"

echo "Load generator running. Watch scaling with tests/kubernetes/hpa-test.sh."
echo "When done, clean up with:"
echo "  kubectl delete pod load-generator -n vehicle-demo"
