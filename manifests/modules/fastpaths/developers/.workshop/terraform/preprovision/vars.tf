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
variable "argocd_admin_group_id" {
  description = <<-EOT
    UUID of an existing AWS IAM Identity Center group whose members are mapped
    to the Argo CD ADMIN role. Must exist in the same Identity Center instance
    found by the preflight in argocd-capability.tf.

    Identity Center users and groups are real human-facing identities (they
    require a real email for activation + MFA enrollment), so this fast path
    treats them as a one-time prerequisite the learner sets up in the IDC
    console rather than creating them in code with placeholder values that
    cannot complete first sign-in. Same approach as
    https://github.com/aws-samples/sample-platform-engineering-on-eks.
  EOT
  type        = string
}
