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

# tflint-ignore: terraform_unused_declarations
variable "inbound_cidrs" {
  description = "CIDR range to allowlist for inbound traffic"
  type        = string
  default     = "0.0.0.0/0"
}

# tflint-ignore: terraform_unused_declarations
variable "enable_eks_capabilities" {
  description = <<-EOT
    Gate for the EKS Capabilities fast path resources (ACK, Argo CD, kro
    capabilities + IAM Identity Center user/group + CodeCommit repo). This
    preprovision module is shared across all fast paths, but only the
    `fastpaths/eks-capabilities` path should create these resources. When
    false (developer/operator paths) nothing capability-related is created,
    so no IAM Identity Center instance is required.
  EOT
  type        = bool
  default     = false
}

# tflint-ignore: terraform_unused_declarations
variable "argocd_admin_email" {
  description = <<-EOT
    Email address attached to the Argo CD workshop admin user record.
    Defaults to a non-deliverable placeholder because this fast path uses the
    admin-generated OTP activation path (see setup-idc.md), not the
    email-link path — so the email value is cosmetic and never needs to
    receive mail. Override with a real address only if you specifically want
    to use the email-link activation flow.

    Pattern adopted from https://github.com/aws-samples/saas-on-eks-workshop-capabilities.
  EOT
  type        = string
  default     = "argocd-admin@example.com"
}
