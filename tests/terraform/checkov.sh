#!/bin/bash
# Runs Checkov against the Terraform code. Needs `pip install checkov`
# locally; CI runs this via the bridgecrewio/checkov-action instead (see
# .github/workflows/platform-security.yml) so this script is for local use.
set -e
cd "$(dirname "$0")/../.."
checkov -d terraform/ --framework terraform --compact
