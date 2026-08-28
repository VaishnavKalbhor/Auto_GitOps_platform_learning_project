# Autoscaling and Self-Healing

*(Before/after evidence below is planned, not yet captured -- see docs/learning-log.md for what's code-only vs. actually run.)*

## HPA Test

### Prerequisite

`metrics-server` must be running (EKS doesn't install it by default):

```bash
aws eks create-addon --cluster-name autogitops-dev --addon-name metrics-server
```

### Procedure

1. Terminal 1: `tests/load/generate-load.sh` -- starts a busybox pod hammering
   `vehicle-telemetry-demo` with requests.
2. Terminal 2: `tests/kubernetes/hpa-test.sh` -- watches `kubectl get hpa` and
   the Deployment's replica count.
3. Wait for CPU utilization to cross the 60% target (`hpa.yaml`'s
   `averageUtilization`).
4. Confirm the HPA scales replicas up (toward `maxReplicas: 5`).
5. Stop the load: `kubectl delete pod load-generator -n vehicle-demo`.
6. Confirm the HPA scales back down toward `minReplicas: 2` after the
   default stabilization window (~5 minutes).

### Result (fill in after running)

| | |
|---|---|
| Initial replicas | 2 |
| Scaled replicas | *(TBD)* |
| Observed metric | CPU utilization |
| Time to scale up | *(TBD)* |
| Time to scale back down | *(TBD)* |

Screenshots: `docs/screenshots/hpa-before-load.png`,
`docs/screenshots/hpa-after-load.png`, `docs/screenshots/pods-scaled.png`.

## Self-Healing Test

### Pod failure

```bash
kubectl get pods -n vehicle-demo
kubectl delete pod <pod-name> -n vehicle-demo
kubectl get pods -n vehicle-demo -w
```

Expected result: Kubernetes creates a replacement pod immediately, because
the Deployment's desired state still requires the configured replica count
-- the Deployment controller continuously reconciles observed vs. desired
state and this is exactly the mismatch it exists to fix.

Screenshots: `docs/screenshots/pod-before-delete.png`,
`docs/screenshots/pod-recreated.png`.

### Node-level test (safer option: cordon/drain)

```bash
kubectl get nodes
kubectl cordon <node-name>
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
kubectl get pods -A -o wide
```

Expected result: pods that were on the drained node get rescheduled onto
the remaining node(s). Uncordon afterward (`kubectl uncordon <node-name>`) or
just let `terraform destroy` clean everything up if this is the last test of
the session.

Screenshot: `docs/screenshots/node-cordon-test.png`.

A harsher AWS-level test (terminating a worker node's EC2 instance directly
from the console and watching the managed node group replace it) is
documented as optional -- for a student portfolio, the pod-delete + drain
tests above are enough to demonstrate the concept without the extra risk of
fiddling with EC2 instances directly.

### Learning

Self-healing is not magic -- Kubernetes continuously compares the desired
state (from the Deployment/ReplicaSet spec) against the actual observed
state (from the API server's view of running pods) and acts whenever they
differ. Deleting a pod, draining a node, or a node crashing all produce the
same kind of mismatch, and the same reconciliation loop handles all of them.
