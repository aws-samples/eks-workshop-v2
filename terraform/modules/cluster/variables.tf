variable "environment_name" {
  type        = string
  description = "Workshop environment name"
}

variable "cluster_version" {
  type        = string
  description = "EKS cluster version"
  default     = "1.23"
}

variable "ami_release_version" {
  description = "Default EKS AMI release version for node groups"
  type        = string
  default     = "1.23.9-20221027"
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

variable "fsx_capacity" {
  type = number
  description = "default FSxN storage capacity"
  default = 2048
}

variable "fsx_admin_password" {
  type = string
  description = "default FSxN filesystem admin password"
  default = "Netapp1!"
}

