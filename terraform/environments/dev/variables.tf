variable "aws_region" {
  description = "AWS region for the dev environment."
  type        = string
  default     = "eu-central-1"
}

variable "azs" {
  description = "Availability zones to use in this region."
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "autogitops-dev"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.29"
}

variable "node_instance_type" {
  description = "EC2 instance type for the managed node group."
  type        = string
  default     = "t3.small"
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}
