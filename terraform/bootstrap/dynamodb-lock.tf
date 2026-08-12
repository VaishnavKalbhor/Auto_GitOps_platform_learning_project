# Classic S3 + DynamoDB state locking. (Newer Terraform/AWS provider versions
# support S3-native locking via `use_lockfile` on the s3 backend block instead
# -- this project uses the DynamoDB table for broader compatibility, since it
# works with any Terraform >= 1.5 and any recent AWS provider version.)
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "autogitops-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project   = "autogitops-platform"
    Purpose   = "terraform-state-locking"
    ManagedBy = "terraform"
  }
}
