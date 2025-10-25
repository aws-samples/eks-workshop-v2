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

variable "cluster_proportional_autoscaler_version" {
  description = "The version of cluster-proportional-autoscaler to use"
  type        = string
  # renovate: datasource=github-releases depName=kubernetes-sigs/cluster-proportional-autoscaler
  default = "1.9.0"
}

variable "cluster_proportional_autoscaler_chart_version" {
  description = "The chart version of cluster-proportional-autoscaler to use"
  type        = string
  # renovate-helm: depName=cluster-proportional-autoscaler registryUrl=https://kubernetes-sigs.github.io/cluster-proportional-autoscaler
  default = "1.1.0"
}