variable "eks_cluster_id" {
  type = string
}

variable "eks_cluster_version" {
  type = string
}

variable "cluster_security_group_id" {
  type = any
}

variable "addon_context" {
  type = any
}

variable "tags" {
  type = any
}

variable "resources_precreated" {
  type = bool
}
