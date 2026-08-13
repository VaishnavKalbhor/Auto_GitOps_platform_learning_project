#!/bin/bash
# Formats and validates the dev environment's Terraform code.
# Does NOT touch AWS or need credentials (`-backend=false`) -- safe to run
# in CI or before every commit.
set -e
cd "$(dirname "$0")/../../terraform/environments/dev"
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate
