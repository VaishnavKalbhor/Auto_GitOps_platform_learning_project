variable "cluster_name" {
  description = "EKS cluster name, used to name/tag the IAM roles."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
