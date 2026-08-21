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
