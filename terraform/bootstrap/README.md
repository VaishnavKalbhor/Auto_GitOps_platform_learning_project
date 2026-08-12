# Terraform Bootstrap

Run this **once**, before anything under `terraform/environments/`, to create the
S3 bucket and DynamoDB table that hold this project's remote Terraform state.

```bash
cd terraform/bootstrap
terraform init
terraform fmt -check
terraform validate
terraform plan -var="state_bucket_name=autogitops-terraform-state-<yourname>"
terraform apply -var="state_bucket_name=autogitops-terraform-state-<yourname>"
```

Take the resulting `state_bucket_name` and `dynamodb_lock_table_name` outputs
and put them into `terraform/environments/dev/backend.tf`.

This bootstrap state itself intentionally stays **local** (no remote backend
configured here) -- it's the one piece of Terraform state that has nowhere
else to live before this step runs. Keep `terraform.tfstate` for this
directory somewhere safe (or re-run bootstrap if you lose it; recreating an
S3 bucket + DynamoDB table is cheap and low-risk compared to environment
infrastructure).

Do **not** run `terraform destroy` here casually -- the state bucket has
`prevent_destroy` set for exactly that reason, but the DynamoDB table does not.
