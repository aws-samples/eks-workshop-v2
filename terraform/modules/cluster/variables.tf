variable "cluster_version" {
  type        = string
  description = "Kubernetes Version"
  default     = "1.23"
}

variable "ami_release_version" {
  default = "1.23.9-20221027"
}

variable "id" {
  type        = string
  description = "Identifier for the cluster"
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