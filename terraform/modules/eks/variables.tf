variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.29"
}

variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS control plane (from the iam module)."
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for the managed node group (from the iam module)."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "Worker nodes run in private subnets only."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "The EKS control plane's ENIs also need access to public subnets when the cluster endpoint is public (the default here, see docs/security-findings.md for the tradeoff)."
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Whether the EKS API server endpoint is reachable from the public internet. true for this learning project (simplest kubectl access); a production platform should set this false and use a VPN/bastion instead -- see docs/security-findings.md."
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  type    = bool
  default = true
}

variable "node_instance_type" {
  type    = string
  default = "t3.small"
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

variable "tags" {
  type    = map(string)
  default = {}
}
