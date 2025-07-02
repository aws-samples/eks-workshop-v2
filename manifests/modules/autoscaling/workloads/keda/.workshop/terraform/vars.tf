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

variable "load_balancer_controller_chart_version" {
  description = "The chart version of aws-load-balancer-controller to use"
  type        = string
  # renovate-helm: depName=aws-load-balancer-controller
  default = "2.8.1"
}

variable "keda_chart_version" {
  description = "The chart version of keda to use"
  type        = string
  # renovate-helm: depName=keda registryUrl=https://kedacore.github.io/charts
  default = "2.17.2"
}
