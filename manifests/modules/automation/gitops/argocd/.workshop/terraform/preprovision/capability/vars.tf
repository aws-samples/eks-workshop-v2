variable "eks_cluster_id" {
  description = "EKS cluster name to enable the Argo CD capability on"
  type        = string
}

variable "idc_group_name" {
  description = "Display name of the Identity Center group to grant the Argo CD ADMIN role"
  type        = string
}

variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = any
  default     = {}
}

# Passed by the lab module when the IDE role applies this directly. Left null by
# hack/pre-provision-resources.sh, whose identity is not bound by the boundary.
variable "iam_permissions_boundary_arn" {
  description = "Permissions boundary for the IAM roles this module creates. Null means none."
  type        = string
  default     = null
}
