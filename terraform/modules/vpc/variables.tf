variable "name" {
  description = "Name prefix for VPC resources."
  type        = string
  default     = "autogitops"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across. Keep this to 2 for a learning project -- it's enough for EKS's HA requirements without tripling NAT Gateway cost."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ."
  type        = list(string)
  default     = ["10.20.0.0/20", "10.20.16.0/20"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (worker nodes), one per AZ."
  type        = list(string)
  default     = ["10.20.128.0/20", "10.20.144.0/20"]
}

variable "single_nat_gateway" {
  description = "If true, create only ONE NAT Gateway (shared by all private subnets) instead of one per AZ. Saves ~2/3 of NAT Gateway cost for a learning project; a real production setup would use one per AZ for resilience."
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name, used to tag subnets so the AWS Load Balancer Controller and EKS itself can auto-discover them (kubernetes.io/cluster/<name> and kubernetes.io/role/* tags)."
  type        = string
}

variable "tags" {
  description = "Extra tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
