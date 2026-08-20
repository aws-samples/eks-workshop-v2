variable "eks_cluster_id" {
  description = "EKS cluster name to enable the Argo CD capability on"
  type        = string
}

variable "idc_instance_arn" {
  description = "ARN of the IAM Identity Center instance that authenticates Argo CD users"
  type        = string
}

variable "idc_user_id" {
  description = "Identity Center user ID to grant the Argo CD ADMIN role"
  type        = string
}

variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = any
  default     = {}
}
