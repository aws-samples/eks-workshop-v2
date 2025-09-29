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

variable "cluster_autoscaler_version" {
  description = "The version of cluster-autoscaler to use"
  type        = string
  # renovate: datasource=github-releases depName=kubernetes/autoscaler
  default = "1.33.0"
}

variable "cluster_autoscaler_chart_version" {
  description = "The chart version of cluster-autoscaler to use"
  type        = string
  # renovate-helm: depName=cluster-autoscaler registryUrl=https://kubernetes.github.io/autoscaler
  default = "9.50.1"
}
