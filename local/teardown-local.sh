#!/bin/bash
# Deletes the local kind cluster and everything in it. Costs nothing to
# leave running (it's just local Docker containers, not billed AWS
# resources) but there's no reason not to clean it up when you're done.
set -e
kind delete cluster --name autogitops-local
echo "Local cluster deleted."
