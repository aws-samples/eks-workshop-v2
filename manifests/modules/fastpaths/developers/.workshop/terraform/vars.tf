# tflint-ignore: terraform_unused_declarations
variable "eks_cluster_id" {
  description = "EKS cluster name"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "eks_cluster_auto_id" {
  description = "EKS Auto Mode cluster name"
  type        = string
  default     = "eks-workshop-auto"
}

# tflint-ignore: terraform_unused_declarations
variable "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  type        = any
}

# tflint-ignore: terraform_unused_declarations
variable "addon_context" {
  description = "Addon context that can be passed directly to blueprints addon modules"
  type        = any
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = any
}

# tflint-ignore: terraform_unused_declarations
variable "resources_precreated" {
  description = "Have expensive resources been created already"
  type        = bool
}

# tflint-ignore: terraform_unused_declarations
variable "inbound_cidrs" {
  description = "CIDR range to allowlist for inbound traffic"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "enable_eks_capabilities" {
  description = "Gate for the eks-capabilities fast path resources (ACK/Argo CD/kro capabilities + IDC + CodeCommit). Only the eks-capabilities path sets this true; dev/operator leave it false. See preprovision/vars.tf."
  type        = bool
  default     = false
}

