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

# tflint-ignore: terraform_unused_declarations
variable "eks_cluster_auto_id" {
  description = "EKS Auto Mode cluster name"
  type        = string
  default     = "eks-workshop-auto"
}