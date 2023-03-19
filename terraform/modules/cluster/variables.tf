variable "environment_name" {
  type        = string
  description = "Workshop environment name"
}

variable "cluster_version" {
  type        = string
  description = "EKS cluster version"
  default     = "1.23"
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth ConfigMap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "tags" {
  type        = map(string)
  description = "AWS tags that will be applied to all resources"
  default     = {}
}
