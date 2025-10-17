resource "random_string" "fluentbit_log_group" {
  length  = 6
  special = false
}

locals {
  cw_log_group_name = "/${var.addon_context.eks_cluster_id}/worker-fluentbit-logs-${random_string.fluentbit_log_group.result}"
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.22.0"

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  enable_aws_for_fluentbit = true

  aws_for_fluentbit = {
    chart_version = "0.1.32"

    role_name   = "${var.addon_context.eks_cluster_id}-fluent-bit"
    policy_name = "${var.addon_context.eks_cluster_id}-fluent-bit"

    wait = true
  }

  aws_for_fluentbit_cw_log_group = local.cw_log_group_name

  observability_tag = null
}

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

output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    CLOUDWATCH_LOG_GROUP_NAME = local.cw_log_group_name
  }
}