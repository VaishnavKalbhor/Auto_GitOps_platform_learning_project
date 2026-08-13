terraform {
  backend "s3" {
    # Fill these in with the outputs from terraform/bootstrap, or pass them
    # via `terraform init -backend-config=...` / CLI -backend-config flags
    # so this file doesn't need editing (and doesn't need to be committed
    # with real values).
    #
    # bucket         = "autogitops-terraform-state-<yourname>"
    # key            = "environments/dev/terraform.tfstate"
    # region         = "eu-central-1"
    # dynamodb_table = "autogitops-terraform-locks"
    # encrypt        = true
  }
}
