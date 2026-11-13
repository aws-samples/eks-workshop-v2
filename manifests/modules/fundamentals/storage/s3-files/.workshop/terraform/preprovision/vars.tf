# tflint-ignore: terraform_unused_declarations
variable "eks_cluster_id" {
  description = "EKS cluster name"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = any
}

# Passed by the lab module when the IDE role applies this directly. Left null by
# hack/pre-provision-resources.sh, whose identity is not bound by the boundary.
variable "iam_permissions_boundary_arn" {
  description = "Permissions boundary for the IAM roles this module creates. Null means none."
  type        = string
  default     = null
}
