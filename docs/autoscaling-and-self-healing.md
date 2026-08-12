# Autoscaling and Self-Healing

*(To be filled in with real before/after evidence once load and failure tests are run against a live cluster — see Day 11/12 in the learning log.)*

## Planned HPA test

Generate load against `vehicle-telemetry-demo` with `tests/load/generate-load.sh`, then watch `tests/kubernetes/hpa-test.sh` output as the Horizontal Pod Autoscaler scales replicas up in response to CPU utilization crossing the 60% target.

## Planned self-healing test

Delete a running pod directly and confirm the Deployment controller replaces it automatically, restoring the desired replica count without manual intervention. Optionally cordon/drain a node and observe pod rescheduling.
