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
    capabilities + CodeCommit repo). This preprovision module is shared across
    all fast paths, but at lab time only the `fastpaths/eks-capabilities` path
    should create these resources: the developer and operator paths would pay
    for a capability they never use, and the Argo CD one additionally needs an
    IAM Identity Center instance their apply has no reason to require.

    The default is true because it only takes effect for one of this module's two
    callers. `hack/pre-provision-resources.sh` generates a wrapper that passes
    nothing but `eks_cluster_id` and `tags`, so a false default meant every
    resource in these files was skipped at a Workshop Studio event and the
    capabilities existed nowhere: pre-provisioning gated them off, and the lab
    skipped this whole module because `resources_precreated` was true.

    At lab time the value is always explicit -- reset-environment exports
    TF_VAR_enable_eks_capabilities and ../main.tf passes it through -- so this
    default never applies there and the dev/operator paths still create nothing.
  EOT
  type        = bool
  default     = true
}

