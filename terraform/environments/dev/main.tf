module "vpc" {
  source = "../../modules/vpc"

  name         = "autogitops-dev"
  cluster_name = var.cluster_name
  azs          = var.azs
}

# module "iam" and module "eks" are added on top of this in Day 4 -- see
# terraform/modules/iam and terraform/modules/eks.
